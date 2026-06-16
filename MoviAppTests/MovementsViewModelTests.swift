import XCTest
@testable import MoviApp

@MainActor
final class MovementsViewModelTests: XCTestCase {
    func testInitialLoadFetchesFirstPage() async {
        let first = TestFactory.movement(daysAgo: 0)
        let repository = MockMovementRepository(pages: [TestFactory.page([first], page: 1, hasNextPage: false)])
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.sections.flatMap(\.rows).map(\.id), [first.id])
        XCTAssertEqual(repository.queries.map(\.page), [1])
    }

    func testInfiniteScrollLoadsNextPage() async {
        let first = TestFactory.movement(daysAgo: 0)
        let second = TestFactory.movement(daysAgo: 1)
        let repository = MockMovementRepository(
            pages: [
                TestFactory.page([first], page: 1, hasNextPage: true),
                TestFactory.page([second], page: 2, hasNextPage: false)
            ]
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadMoreIfNeeded(currentItemID: first.id)

        XCTAssertEqual(viewModel.sections.flatMap(\.rows).map(\.id), [first.id, second.id])
        XCTAssertEqual(repository.queries.map(\.page), [1, 2])
    }

    func testAvoidsDuplicateLoadMoreWhileLoading() async {
        let first = TestFactory.movement(daysAgo: 0)
        let second = TestFactory.movement(daysAgo: 1)
        let repository = MockMovementRepository(
            pages: [
                TestFactory.page([first], page: 1, hasNextPage: true),
                TestFactory.page([second], page: 2, hasNextPage: false)
            ]
        )
        repository.delayNanoseconds = 120_000_000
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()

        async let loadA: Void = viewModel.loadMoreIfNeeded(currentItemID: first.id)
        async let loadB: Void = viewModel.loadMoreIfNeeded(currentItemID: first.id)
        _ = await (loadA, loadB)

        XCTAssertEqual(repository.queries.map(\.page), [1, 2])
    }

    func testArchiveAndUnarchiveMovement() async {
        let movement = TestFactory.movement(daysAgo: 0)
        let repository = MockMovementRepository(pages: [TestFactory.page([movement], page: 1, hasNextPage: false)])
        let archiveStore = InMemoryArchivedMovementStore()
        let viewModel = makeViewModel(repository: repository, archiveStore: archiveStore)

        await viewModel.loadInitialIfNeeded()
        let row = viewModel.sections.flatMap(\.rows)[0]

        await viewModel.toggleArchive(for: row)
        viewModel.setFilter(.archived)
        XCTAssertEqual(viewModel.sections.flatMap(\.rows).map(\.id), [movement.id])

        let archivedRow = viewModel.sections.flatMap(\.rows)[0]
        await viewModel.toggleArchive(for: archivedRow)
        XCTAssertEqual(viewModel.state, .empty)
    }

    func testFiltersArchivedAndUnarchived() async {
        let archived = TestFactory.movement(daysAgo: 0)
        let unarchived = TestFactory.movement(daysAgo: 1)
        let repository = MockMovementRepository(pages: [TestFactory.page([archived, unarchived], page: 1, hasNextPage: false)])
        let archiveStore = InMemoryArchivedMovementStore(ids: [archived.id])
        let viewModel = makeViewModel(repository: repository, archiveStore: archiveStore)

        await viewModel.loadInitialIfNeeded()

        viewModel.setFilter(.archived)
        XCTAssertEqual(viewModel.sections.flatMap(\.rows).map(\.id), [archived.id])

        viewModel.setFilter(.unarchived)
        XCTAssertEqual(viewModel.sections.flatMap(\.rows).map(\.id), [unarchived.id])
    }

    func testPullToRefreshResetsPagination() async {
        let first = TestFactory.movement(daysAgo: 0, reference: "first")
        let second = TestFactory.movement(daysAgo: 1, reference: "second")
        let refreshed = TestFactory.movement(daysAgo: 2, reference: "refreshed")
        let repository = MockMovementRepository(
            pages: [
                TestFactory.page([first], page: 1, hasNextPage: true),
                TestFactory.page([second], page: 2, hasNextPage: false),
                TestFactory.page([refreshed], page: 1, hasNextPage: false)
            ]
        )
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()
        await viewModel.loadMoreIfNeeded(currentItemID: first.id)
        repository.pages = [TestFactory.page([refreshed], page: 1, hasNextPage: false)]
        await viewModel.refresh()

        XCTAssertEqual(repository.queries.map(\.page), [1, 2, 1])
        XCTAssertEqual(viewModel.sections.flatMap(\.rows).map(\.id), [refreshed.id])
    }

    func testSelectingMovementLoadsDetail() async {
        let movement = TestFactory.movement(daysAgo: 0)
        let detail = TestFactory.movement(
            id: movement.id,
            daysAgo: 0,
            amount: Decimal(30.55),
            reference: "BG-20260616-000455-819"
        )
        let repository = MockMovementRepository(pages: [TestFactory.page([movement], page: 1, hasNextPage: false)])
        repository.details[movement.id] = detail
        let viewModel = makeViewModel(repository: repository)

        await viewModel.loadInitialIfNeeded()
        let row = viewModel.sections.flatMap(\.rows)[0]
        await viewModel.selectMovement(row)

        XCTAssertEqual(repository.detailIDs, [movement.id])
        XCTAssertEqual(viewModel.detailState, .loaded(MovementRowViewState(movement: detail, isArchived: false)))
        XCTAssertTrue(viewModel.isDetailPresented)
    }

    private func makeViewModel(repository: MockMovementRepository) -> MovementsViewModel {
        makeViewModel(repository: repository, archiveStore: InMemoryArchivedMovementStore())
    }

    private func makeViewModel(
        repository: MockMovementRepository,
        archiveStore: InMemoryArchivedMovementStore
    ) -> MovementsViewModel {
        MovementsViewModel(
            repository: repository,
            archivedStore: archiveStore,
            config: AppConfig(baseURL: URL(string: "https://example.com")!, defaultPageSize: 30),
            dateGrouper: MovementDateGrouper(calendar: .gregorianUTC),
            calendar: .gregorianUTC
        )
    }
}

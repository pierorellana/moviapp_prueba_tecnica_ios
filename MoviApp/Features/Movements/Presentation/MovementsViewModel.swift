import Combine
import Foundation

@MainActor
final class MovementsViewModel: ObservableObject {
    enum ViewState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case error(String)
    }

    @Published private(set) var state: ViewState = .idle
    @Published private(set) var sections: [MovementSectionViewState] = []
    @Published private(set) var searchText = ""
    @Published private(set) var selectedFilter: ArchiveFilter = .all
    @Published private(set) var selectedRange: MovementDateRange = .thirty
    @Published private(set) var isLoadingMore = false
    @Published private(set) var isRefreshing = false
    @Published private(set) var isDetailPresented = false
    @Published private(set) var detailState: MovementDetailViewState = .idle
    @Published private(set) var actionMessage: String?

    var visibleMovementCount: Int {
        sections.reduce(0) { $0 + $1.rows.count }
    }

    var visibleNetAmountText: String {
        let rows = sections.flatMap(\.rows)
        let currency = rows.first?.movement.currency ?? "USD"
        let total = rows.reduce(Decimal.zero) { partialResult, row in
            partialResult + row.movement.amount
        }
        return MovementFormatters.amount(total, currency: currency)
    }

    var visibleCreditCount: Int {
        sections.flatMap(\.rows).filter { $0.movement.amount >= Decimal.zero }.count
    }

    var visibleDebitCount: Int {
        sections.flatMap(\.rows).filter { $0.movement.amount < Decimal.zero }.count
    }

    private let repository: MovementRepositoryProtocol
    private let archivedStore: ArchivedMovementStoreProtocol
    private let config: AppConfig
    private let dateGrouper: MovementDateGrouper
    private let calendar: Calendar

    private var loadedMovements: [Movement] = []
    private var archivedIDs: Set<UUID> = []
    private var currentPage = 0
    private var hasNextPage = true
    private var selectedDetailFallbackRow: MovementRowViewState?
    private var searchTask: Task<Void, Never>?
    private var actionMessageTask: Task<Void, Never>?

    init(
        repository: MovementRepositoryProtocol,
        archivedStore: ArchivedMovementStoreProtocol,
        config: AppConfig,
        dateGrouper: MovementDateGrouper,
        calendar: Calendar
    ) {
        self.repository = repository
        self.archivedStore = archivedStore
        self.config = config
        self.dateGrouper = dateGrouper
        self.calendar = calendar
    }

    deinit {
        searchTask?.cancel()
        actionMessageTask?.cancel()
    }

    func loadInitialIfNeeded() async {
        guard state == .idle else {
            return
        }
        await loadFirstPage(isRefresh: false)
    }

    func refresh() async {
        await loadFirstPage(isRefresh: true)
    }

    func setSearchText(_ text: String) {
        searchText = text
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await self?.loadFirstPage(isRefresh: true)
        }
    }

    func setFilter(_ filter: ArchiveFilter) {
        selectedFilter = filter
        rebuildSections()
    }

    func setDateRange(_ range: MovementDateRange) async {
        guard selectedRange != range else {
            return
        }
        selectedRange = range
        await loadFirstPage(isRefresh: true)
    }

    func loadMoreIfNeeded(currentItemID: UUID) async {
        guard shouldLoadMore(currentItemID: currentItemID) else {
            return
        }

        await loadNextPage()
    }

    func selectMovement(_ row: MovementRowViewState) async {
        selectedDetailFallbackRow = row
        isDetailPresented = true
        detailState = .loading(row)

        do {
            let movement = try await repository.fetchMovementDetail(id: row.id)
            detailState = .loaded(MovementRowViewState(movement: movement, isArchived: archivedIDs.contains(row.id)))
        } catch {
            detailState = .error(row, error.localizedDescription)
        }
    }

    func retrySelectedMovementDetail() async {
        guard let row = selectedDetailFallbackRow else {
            return
        }

        await selectMovement(row)
    }

    func dismissMovementDetail() {
        isDetailPresented = false
        detailState = .idle
        selectedDetailFallbackRow = nil
    }

    func dismissActionMessage() {
        actionMessageTask?.cancel()
        actionMessageTask = nil
        actionMessage = nil
    }

    func toggleSelectedDetailArchive() async {
        guard case .loaded(let row) = detailState else {
            return
        }

        await toggleArchive(for: row)
        detailState = .loaded(MovementRowViewState(movement: row.movement, isArchived: archivedIDs.contains(row.id)))
    }

    func toggleArchive(for row: MovementRowViewState) async {
        do {
            if row.isArchived {
                try await archivedStore.unarchive(id: row.id)
                archivedIDs.remove(row.id)
                showActionMessage("Movimiento desarchivado")
            } else {
                try await archivedStore.archive(id: row.id)
                archivedIDs.insert(row.id)
                showActionMessage("Movimiento archivado")
            }
            rebuildSections()
            syncDetailArchiveState(for: row.id)
        } catch {
            showActionMessage("No se pudo actualizar el archivo local.")
        }
    }

    private func loadFirstPage(isRefresh: Bool) async {
        if isRefresh {
            isRefreshing = true
        } else {
            state = .loading
        }

        defer {
            isRefreshing = false
        }

        do {
            let page = try await repository.fetchMovements(query: makeQuery(page: 1))
            archivedIDs = try await archivedStore.fetchArchivedIDs()
            loadedMovements = page.items
            currentPage = page.page
            hasNextPage = page.hasNextPage
            rebuildSections()
        } catch {
            loadedMovements = []
            sections = []
            state = .error(error.localizedDescription)
        }
    }

    private func loadNextPage() async {
        guard hasNextPage, !isLoadingMore else {
            return
        }

        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let nextPage = currentPage + 1
            let page = try await repository.fetchMovements(query: makeQuery(page: nextPage))
            archivedIDs = try await archivedStore.fetchArchivedIDs()
            appendUnique(page.items)
            currentPage = page.page
            hasNextPage = page.hasNextPage
            rebuildSections()
        } catch {
            showActionMessage("No se pudo cargar más movimientos.")
        }
    }

    private func appendUnique(_ movements: [Movement]) {
        var knownIDs = Set(loadedMovements.map(\.id))
        let newItems = movements.filter { knownIDs.insert($0.id).inserted }
        loadedMovements.append(contentsOf: newItems)
    }

    private func makeQuery(page: Int) -> MovementQuery {
        let now = Date()
        let fromDate = calendar.date(byAdding: .day, value: -selectedRange.rawValue, to: now)
        return MovementQuery(
            page: page,
            pageSize: config.defaultPageSize,
            fromDate: fromDate,
            toDate: now,
            search: searchText.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        )
    }

    private func shouldLoadMore(currentItemID: UUID) -> Bool {
        guard hasNextPage, !isLoadingMore else {
            return false
        }

        let rows = sections.flatMap(\.rows)
        guard let index = rows.firstIndex(where: { $0.id == currentItemID }) else {
            return false
        }

        return index >= max(rows.count - 6, 0)
    }

    private func rebuildSections() {
        let rows = loadedMovements
            .map { MovementRowViewState(movement: $0, isArchived: archivedIDs.contains($0.id)) }
            .filter { row in
                switch selectedFilter {
                case .all:
                    return true
                case .archived:
                    return row.isArchived
                case .unarchived:
                    return !row.isArchived
                }
            }

        let grouped = Dictionary(grouping: rows) { row in
            dateGrouper.group(for: row.movement.transactionDate) ?? .threeMonthsAgo
        }

        sections = MovementDateGroup.allCases.compactMap { group in
            guard let rows = grouped[group], !rows.isEmpty else {
                return nil
            }

            return MovementSectionViewState(
                group: group,
                rows: rows.sorted { $0.movement.transactionDate > $1.movement.transactionDate }
            )
        }

        state = sections.isEmpty ? .empty : .loaded
    }

    private func syncDetailArchiveState(for id: UUID) {
        guard case .loaded(let row) = detailState, row.id == id else {
            return
        }

        detailState = .loaded(MovementRowViewState(movement: row.movement, isArchived: archivedIDs.contains(id)))
    }

    private func showActionMessage(_ message: String) {
        actionMessageTask?.cancel()
        actionMessage = message
        actionMessageTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 2_400_000_000)
            guard !Task.isCancelled else {
                return
            }
            self?.dismissActionMessage()
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

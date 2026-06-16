import Foundation
@testable import MoviApp

struct MockBiometricService: BiometricAuthenticating {
    var availabilityResult: BiometricAvailability = .available(.faceID)
    var authenticationError: BiometricAuthenticationError?

    func availability() -> BiometricAvailability {
        availabilityResult
    }

    func authenticate(reason: String) async throws {
        if let authenticationError {
            throw authenticationError
        }
    }
}

@MainActor
final class InMemoryArchivedMovementStore: ArchivedMovementStoreProtocol {
    private(set) var ids: Set<UUID>

    init(ids: Set<UUID> = []) {
        self.ids = ids
    }

    func fetchArchivedIDs() async throws -> Set<UUID> {
        ids
    }

    func archive(id: UUID) async throws {
        ids.insert(id)
    }

    func unarchive(id: UUID) async throws {
        ids.remove(id)
    }
}

final class MockMovementRepository: MovementRepositoryProtocol {
    var pages: [MovementPage]
    var queries: [MovementQuery] = []
    var detailIDs: [UUID] = []
    var details: [UUID: Movement] = [:]
    var delayNanoseconds: UInt64 = 0

    init(pages: [MovementPage]) {
        self.pages = pages
    }

    func fetchMovements(query: MovementQuery) async throws -> MovementPage {
        queries.append(query)

        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }

        let index = max(0, min(query.page - 1, pages.count - 1))
        return pages[index]
    }

    func fetchMovementDetail(id: UUID) async throws -> Movement {
        detailIDs.append(id)

        if let detail = details[id] {
            return detail
        }

        return pages.flatMap(\.items).first { $0.id == id } ?? TestFactory.movement(id: id, daysAgo: 0)
    }
}

enum TestFactory {
    static func movement(
        id: UUID = UUID(),
        daysAgo: Int,
        amount: Decimal = Decimal(12.45),
        reference: String = UUID().uuidString
    ) -> Movement {
        let calendar = Calendar.gregorianUTC
        let baseDate = calendar.date(from: DateComponents(year: 2026, month: 6, day: 16, hour: 12))!
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: baseDate)!

        return Movement(
            id: id,
            accountId: UUID(uuidString: "3AC3D1C2-4468-405A-ADA2-1A87377C85C3"),
            type: amount < Decimal(0) ? .debit : .credit,
            personName: "Maria Fernanda Torres",
            description: "Transferencia recibida",
            reference: reference,
            amount: amount,
            currency: "USD",
            status: .charged,
            transactionDate: date,
            createdAt: date.addingTimeInterval(1_800),
            category: "Transferencias",
            channel: "Mobile"
        )
    }

    static func page(_ items: [Movement], page: Int, hasNextPage: Bool) -> MovementPage {
        MovementPage(
            items: items,
            page: page,
            pageSize: 30,
            totalItems: items.count,
            totalPages: hasNextPage ? page + 1 : page,
            hasPreviousPage: page > 1,
            hasNextPage: hasNextPage
        )
    }
}

extension Calendar {
    static var gregorianUTC: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.firstWeekday = 2
        return calendar
    }
}

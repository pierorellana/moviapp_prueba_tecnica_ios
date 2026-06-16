import Foundation

extension AppDependencyContainer {
    static var preview: AppDependencyContainer {
        AppDependencyContainer(
            config: .live,
            biometricService: PreviewBiometricService(),
            movementRepository: PreviewMovementRepository(),
            archivedMovementStore: CoreDataArchivedMovementStore(inMemory: true)
        )
    }
}

private struct PreviewBiometricService: BiometricAuthenticating {
    func availability() -> BiometricAvailability {
        .available(.faceID)
    }

    func authenticate(reason: String) async throws {}
}

private struct PreviewMovementRepository: MovementRepositoryProtocol {
    func fetchMovements(query: MovementQuery) async throws -> MovementPage {
        let now = Date()
        let items = (0..<12).map { makeMovement(index: $0, now: now) }

        return MovementPage(
            items: items,
            page: 1,
            pageSize: 30,
            totalItems: items.count,
            totalPages: 1,
            hasPreviousPage: false,
            hasNextPage: false
        )
    }

    func fetchMovementDetail(id: UUID) async throws -> Movement {
        makeMovement(index: 0, now: Date(), id: id)
    }

    private func makeMovement(index: Int, now: Date, id: UUID = UUID()) -> Movement {
        let names = ["Maria Fernanda Torres", "Carlos Andres Mendoza", "Andrea Vera"]
        let descriptions = ["Transferencia recibida", "Pago de servicio", "Compra en supermercado"]
        let isCredit = index.isMultiple(of: 2)
        let amount = isCredit ? Decimal(42 + index) : Decimal(-18 - index)
        let date = Calendar.current.date(byAdding: .day, value: -index, to: now) ?? now

        return Movement(
            id: id,
            accountId: UUID(uuidString: "3AC3D1C2-4468-405A-ADA2-1A87377C85C3"),
            type: isCredit ? .credit : .debit,
            personName: names[index % names.count],
            description: descriptions[index % descriptions.count],
            reference: "BG-20260616-\(String(format: "%06d", index))",
            amount: amount,
            currency: "USD",
            status: index.isMultiple(of: 3) ? .pending : .charged,
            transactionDate: date,
            createdAt: date.addingTimeInterval(1_800),
            category: "Transferencias",
            channel: "Mobile"
        )
    }
}

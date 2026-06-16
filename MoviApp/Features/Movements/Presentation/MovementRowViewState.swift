import Foundation

struct MovementRowViewState: Identifiable, Equatable {
    let movement: Movement
    let isArchived: Bool

    var id: UUID { movement.id }

    var amountText: String {
        MovementFormatters.amount(movement.amount, currency: movement.currency)
    }

    var timeText: String {
        MovementFormatters.timeOrShortDate(movement.transactionDate)
    }
}

struct MovementSectionViewState: Identifiable, Equatable {
    let group: MovementDateGroup
    let rows: [MovementRowViewState]

    var id: Int { group.id }
    var title: String { group.title }
}

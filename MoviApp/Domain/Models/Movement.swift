import Foundation

struct Movement: Identifiable, Equatable {
    let id: UUID
    let accountId: UUID?
    let type: MovementType
    let personName: String
    let description: String
    let reference: String
    let amount: Decimal
    let currency: String
    let status: MovementStatus
    let transactionDate: Date
    let createdAt: Date?
    let category: String
    let channel: String
}

enum MovementType: Equatable {
    case debit
    case credit
    case transfer

    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "debit":
            self = .debit
        case "credit":
            self = .credit
        case "transfer":
            self = .transfer
        default:
            return nil
        }
    }

    var iconName: String {
        switch self {
        case .debit:
            "arrow.up.right"
        case .credit:
            "arrow.down.left"
        case .transfer:
            "arrow.left.arrow.right"
        }
    }
}

enum MovementStatus: Equatable {
    case charged
    case pending
    case reversed
    case unknown(String)

    init?(rawValue: String) {
        switch rawValue.lowercased() {
        case "cobrado":
            self = .charged
        case "pendiente":
            self = .pending
        case "reversado":
            self = .reversed
        default:
            self = .unknown(rawValue)
        }
    }

    var title: String {
        switch self {
        case .charged:
            "Cobrado"
        case .pending:
            "Pendiente"
        case .reversed:
            "Reversado"
        case .unknown(let value):
            value
        }
    }
}

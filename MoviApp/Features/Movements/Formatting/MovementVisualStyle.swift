import SwiftUI

extension MovementType {
    var title: String {
        switch self {
        case .debit:
            "Débito"
        case .credit:
            "Crédito"
        case .transfer:
            "Transferencia"
        }
    }

    var tintColor: Color {
        switch self {
        case .debit:
            Color(.systemRed)
        case .credit:
            Color(.systemGreen)
        case .transfer:
            Color(.systemBlue)
        }
    }

    var softColor: Color {
        tintColor.opacity(0.12)
    }
}

extension MovementStatus {
    var tintColor: Color {
        switch self {
        case .charged:
            Color(.systemGreen)
        case .pending:
            Color(.systemOrange)
        case .reversed:
            Color(.systemRed)
        case .unknown:
            Color(.systemGray)
        }
    }
}

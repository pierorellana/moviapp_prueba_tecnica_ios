import Foundation

enum MovementDateRange: Int, CaseIterable, Identifiable {
    case thirty = 30
    case sixty = 60
    case ninety = 90

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .thirty:
            "30 días"
        case .sixty:
            "60 días"
        case .ninety:
            "90 días"
        }
    }
}

import Foundation

enum ArchiveFilter: String, CaseIterable, Identifiable {
    case all
    case archived
    case unarchived

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            "Todos"
        case .archived:
            "Archivados"
        case .unarchived:
            "Desarchivados"
        }
    }
}

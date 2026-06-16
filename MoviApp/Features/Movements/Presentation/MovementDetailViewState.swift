import Foundation

enum MovementDetailViewState: Equatable {
    case idle
    case loading(MovementRowViewState)
    case loaded(MovementRowViewState)
    case error(MovementRowViewState, String)

    var fallbackRow: MovementRowViewState? {
        switch self {
        case .idle:
            nil
        case .loading(let row), .loaded(let row), .error(let row, _):
            row
        }
    }
}

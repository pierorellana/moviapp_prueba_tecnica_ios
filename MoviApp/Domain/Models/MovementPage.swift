import Foundation

struct MovementPage: Equatable {
    let items: [Movement]
    let page: Int
    let pageSize: Int
    let totalItems: Int
    let totalPages: Int
    let hasPreviousPage: Bool
    let hasNextPage: Bool
}

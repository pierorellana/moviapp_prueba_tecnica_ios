import Foundation

struct PaginatedResponseDTO<T: Decodable>: Decodable {
    let items: [T]
    let page: Int
    let pageSize: Int
    let totalItems: Int
    let totalPages: Int
    let hasPreviousPage: Bool
    let hasNextPage: Bool
}

import Foundation

protocol MovementRepositoryProtocol {
    func fetchMovements(query: MovementQuery) async throws -> MovementPage
    func fetchMovementDetail(id: UUID) async throws -> Movement
}

import Foundation

@MainActor
protocol ArchivedMovementStoreProtocol {
    func fetchArchivedIDs() async throws -> Set<UUID>
    func archive(id: UUID) async throws
    func unarchive(id: UUID) async throws
}

import Foundation

@MainActor
final class AppDependencyContainer {
    let biometricService: BiometricAuthenticating
    let movementRepository: MovementRepositoryProtocol
    let archivedMovementStore: ArchivedMovementStoreProtocol
    let config: AppConfig

    init(
        config: AppConfig,
        biometricService: BiometricAuthenticating,
        movementRepository: MovementRepositoryProtocol,
        archivedMovementStore: ArchivedMovementStoreProtocol
    ) {
        self.config = config
        self.biometricService = biometricService
        self.movementRepository = movementRepository
        self.archivedMovementStore = archivedMovementStore
    }

    static func live(config: AppConfig = .live) -> AppDependencyContainer {
        let apiClient = APIClient(baseURL: config.baseURL)
        return AppDependencyContainer(
            config: config,
            biometricService: LocalBiometricAuthenticationService(),
            movementRepository: RemoteMovementRepository(apiClient: apiClient),
            archivedMovementStore: CoreDataArchivedMovementStore()
        )
    }
}

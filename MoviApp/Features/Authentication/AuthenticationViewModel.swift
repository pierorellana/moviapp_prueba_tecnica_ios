import Combine
import Foundation

@MainActor
final class AuthenticationViewModel: ObservableObject {
    enum State: Equatable {
        case idle
        case checking
        case prompting(BiometryKind)
        case authenticated
        case unavailable(BiometricAuthenticationError)
        case failed(BiometricAuthenticationError)
    }

    @Published private(set) var state: State = .idle

    private let service: BiometricAuthenticating
    private var didRequestOnLaunch = false

    init(service: BiometricAuthenticating) {
        self.service = service
    }

    func authenticateOnLaunch() async {
        guard !didRequestOnLaunch else {
            return
        }

        didRequestOnLaunch = true
        await authenticate()
    }

    func authenticate() async {
        state = .checking

        switch service.availability() {
        case .available(let kind):
            state = .prompting(kind)
            do {
                try await service.authenticate(reason: "Confirma tu identidad para consultar tus movimientos.")
                state = .authenticated
            } catch let error as BiometricAuthenticationError {
                state = error == .userCancelled ? .failed(.userCancelled) : .failed(error)
            } catch {
                state = .failed(.failed(error.localizedDescription))
            }
        case .unavailable(let error):
            state = .unavailable(error)
        }
    }
}

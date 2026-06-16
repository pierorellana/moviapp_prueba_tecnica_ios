import Foundation
import LocalAuthentication

enum BiometryKind: Equatable {
    case faceID
    case touchID
    case opticID
    case unknown

    var title: String {
        switch self {
        case .faceID:
            "Face ID"
        case .touchID:
            "Touch ID"
        case .opticID:
            "Optic ID"
        case .unknown:
            "Biometría"
        }
    }
}

enum BiometricAuthenticationError: LocalizedError, Equatable {
    case notAvailable
    case notEnrolled
    case lockedOut
    case userCancelled
    case failed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            "Este dispositivo no tiene biometría disponible."
        case .notEnrolled:
            "No hay biometría configurada en el dispositivo."
        case .lockedOut:
            "La biometría está bloqueada temporalmente."
        case .userCancelled:
            "Autenticación cancelada."
        case .failed(let message):
            message
        }
    }
}

enum BiometricAvailability: Equatable {
    case available(BiometryKind)
    case unavailable(BiometricAuthenticationError)
}

protocol BiometricAuthenticating {
    func availability() -> BiometricAvailability
    func authenticate(reason: String) async throws
}

final class LocalBiometricAuthenticationService: BiometricAuthenticating {
    func availability() -> BiometricAvailability {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return .available(Self.mapBiometryType(context.biometryType))
        }

        return .unavailable(Self.map(error))
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw Self.map(error)
        }

        do {
            _ = try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            throw Self.map(error as NSError)
        }
    }

    private static func mapBiometryType(_ type: LABiometryType) -> BiometryKind {
        switch type {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        case .none:
            return .unknown
        @unknown default:
            return .unknown
        }
    }

    private static func map(_ error: NSError?) -> BiometricAuthenticationError {
        guard let error else {
            return .notAvailable
        }

        guard error.domain == LAError.errorDomain, let code = LAError.Code(rawValue: error.code) else {
            return .failed(error.localizedDescription)
        }

        switch code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .biometryLockout:
            return .lockedOut
        case .userCancel, .appCancel, .systemCancel:
            return .userCancelled
        default:
            return .failed(error.localizedDescription)
        }
    }
}

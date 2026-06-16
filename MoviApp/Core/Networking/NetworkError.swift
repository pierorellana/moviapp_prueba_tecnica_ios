import Foundation

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case invalidResponse
    case httpStatus(Int, String?)
    case decoding(String)
    case emptyData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "No se pudo construir la URL del servicio."
        case .transport(let message):
            "No se pudo conectar con el servicio. \(message)"
        case .invalidResponse:
            "El servicio devolvió una respuesta inválida."
        case .httpStatus(let statusCode, let message):
            message ?? "El servicio respondió con código \(statusCode)."
        case .decoding(let message):
            "No se pudo leer la respuesta del servicio. \(message)"
        case .emptyData:
            "El servicio no devolvió datos."
        }
    }
}

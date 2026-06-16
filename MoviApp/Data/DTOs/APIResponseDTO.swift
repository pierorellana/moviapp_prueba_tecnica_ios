import Foundation

struct APIResponseDTO<T: Decodable>: Decodable {
    let message: String?
    let data: T?
    let error: APIErrorDTO?

    var resolvedErrorMessage: String? {
        message ?? error?.message
    }
}

struct APIErrorDTO: Decodable {
    let message: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let value = try? container.decode(String.self) {
            message = value
            return
        }

        if let values = try? container.decode([String: [String]].self) {
            message = values.flatMap { $0.value }.joined(separator: "\n")
            return
        }

        if let value = try? container.decode([String: String].self) {
            message = value.values.joined(separator: "\n")
            return
        }

        message = "Ocurrió un error en el servicio."
    }
}

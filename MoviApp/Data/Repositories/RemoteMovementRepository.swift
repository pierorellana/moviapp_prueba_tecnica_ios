import Foundation

final class RemoteMovementRepository: MovementRepositoryProtocol {
    private let apiClient: APIClient
    private let dateFormatter: DateFormatter

    init(apiClient: APIClient, dateFormatter: DateFormatter = .apiDayFormatter) {
        self.apiClient = apiClient
        self.dateFormatter = dateFormatter
    }

    func fetchMovements(query: MovementQuery) async throws -> MovementPage {
        let endpoint = Endpoint(path: "api/movements", queryItems: makeQueryItems(query))
        let response: APIResponseDTO<PaginatedResponseDTO<MovementDTO>> = try await apiClient.send(endpoint)

        guard let data = response.data else {
            throw NetworkError.httpStatus(200, response.resolvedErrorMessage ?? "El servicio no devolvió movimientos.")
        }

        return MovementPage(
            items: data.items.map { $0.toDomain() },
            page: data.page,
            pageSize: data.pageSize,
            totalItems: data.totalItems,
            totalPages: data.totalPages,
            hasPreviousPage: data.hasPreviousPage,
            hasNextPage: data.hasNextPage
        )
    }

    func fetchMovementDetail(id: UUID) async throws -> Movement {
        let endpoint = Endpoint(path: "api/Movements/\(id.uuidString)")
        let response: MovementDetailResponseDTO = try await apiClient.send(endpoint)

        guard let movement = response.movement else {
            throw NetworkError.httpStatus(200, response.resolvedErrorMessage ?? "El servicio no devolvió el detalle del movimiento.")
        }

        return movement.toDomain()
    }

    private func makeQueryItems(_ query: MovementQuery) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "page", value: String(query.page)),
            URLQueryItem(name: "pageSize", value: String(query.pageSize)),
            URLQueryItem(name: "sort", value: query.sort)
        ]

        if let fromDate = query.fromDate {
            items.append(URLQueryItem(name: "fromDate", value: dateFormatter.string(from: fromDate)))
        }

        if let toDate = query.toDate {
            items.append(URLQueryItem(name: "toDate", value: dateFormatter.string(from: toDate)))
        }

        if let search = query.search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            items.append(URLQueryItem(name: "search", value: search.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return items
    }
}

private struct MovementDetailResponseDTO: Decodable {
    let movement: MovementDTO?
    let resolvedErrorMessage: String?

    init(from decoder: Decoder) throws {
        if let directMovement = try? MovementDTO(from: decoder) {
            movement = directMovement
            resolvedErrorMessage = nil
            return
        }

        let response = try APIResponseDTO<MovementDTO>(from: decoder)
        movement = response.data
        resolvedErrorMessage = response.resolvedErrorMessage
    }
}

extension DateFormatter {
    static var apiDayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}

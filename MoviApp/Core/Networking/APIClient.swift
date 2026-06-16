import Foundation

protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionProtocol {}

final class APIClient {
    private let baseURL: URL
    private let session: URLSessionProtocol
    private let interceptors: [RequestInterceptor]
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSessionProtocol = URLSession.shared,
        interceptors: [RequestInterceptor] = [DefaultRequestInterceptor()],
        decoder: JSONDecoder = JSONDecoder.apiDecoder
    ) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
        self.decoder = decoder
    }

    func send<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let request = try makeRequest(endpoint)
        let startDate = Date()
        logRequest(request)

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                AppLogger.networkError("[Network] Invalid response for \(request.url?.absoluteString ?? "unknown URL")")
                throw NetworkError.invalidResponse
            }
            logResponse(data: data, response: httpResponse, request: request, startedAt: startDate)

            guard (200...299).contains(httpResponse.statusCode) else {
                let apiMessage = try? decoder.decode(APIResponseDTO<EmptyDTO>.self, from: data).resolvedErrorMessage
                throw NetworkError.httpStatus(httpResponse.statusCode, apiMessage)
            }

            guard !data.isEmpty else {
                throw NetworkError.emptyData
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decoding(error.localizedDescription)
            }
        } catch let error as NetworkError {
            AppLogger.networkError("[Network] Error: \(error.localizedDescription)")
            throw error
        } catch {
            let networkError = NetworkError.transport(error.localizedDescription)
            AppLogger.networkError("[Network] Error: \(networkError.localizedDescription)")
            throw networkError
        }
    }

    private func makeRequest(_ endpoint: Endpoint) throws -> URLRequest {
        let cleanPath = endpoint.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = baseURL.appendingPathComponent(cleanPath)

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkError.invalidURL
        }

        if !endpoint.queryItems.isEmpty {
            components.queryItems = endpoint.queryItems
        }

        guard let finalURL = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: finalURL)
        request.httpMethod = endpoint.method.rawValue
        endpoint.headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        return interceptors.reduce(request) { partialRequest, interceptor in
            interceptor.adapt(partialRequest)
        }
    }

    private func logRequest(_ request: URLRequest) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "unknown URL"
        AppLogger.networkInfo("[Network] Request \(method) \(url)")

        if let body = request.httpBody, !body.isEmpty {
            AppLogger.networkInfo("[Network] Request body:\n\(printableBody(from: body))")
        }
    }

    private func logResponse(
        data: Data,
        response: HTTPURLResponse,
        request: URLRequest,
        startedAt: Date
    ) {
        let elapsedMilliseconds = Int(Date().timeIntervalSince(startedAt) * 1_000)
        let url = request.url?.absoluteString ?? "unknown URL"
        AppLogger.networkInfo("[Network] Response \(response.statusCode) \(url) (\(elapsedMilliseconds) ms)")
        AppLogger.networkInfo("[Network] Response body:\n\(printableBody(from: data))")
    }

    private func printableBody(from data: Data) -> String {
        guard !data.isEmpty else {
            return "<empty>"
        }

        if let jsonObject = try? JSONSerialization.jsonObject(with: data),
           JSONSerialization.isValidJSONObject(jsonObject),
           let prettyData = try? JSONSerialization.data(
            withJSONObject: jsonObject,
            options: [.prettyPrinted, .sortedKeys]
           ),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }

        return String(data: data, encoding: .utf8) ?? "<binary body: \(data.count) bytes>"
    }
}

private struct EmptyDTO: Decodable {}

extension JSONDecoder {
    static var apiDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)

            if let date = DateParsers.iso8601WithFractionalSeconds.date(from: value) {
                return date
            }

            if let date = DateParsers.iso8601.date(from: value) {
                return date
            }

            if let date = DateParsers.dotNetWithTimeZone.date(from: value) {
                return date
            }

            if let date = DateParsers.dotNetWithoutTimeZone.date(from: value) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(value)"
            )
        }
        return decoder
    }
}

private enum DateParsers {
    static let iso8601WithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static let dotNetWithoutTimeZone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSS"
        return formatter
    }()

    static let dotNetWithTimeZone: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSSX"
        return formatter
    }()
}

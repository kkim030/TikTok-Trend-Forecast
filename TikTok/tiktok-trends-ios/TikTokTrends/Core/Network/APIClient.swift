import Foundation

// Base URL — Debug builds (Xcode → simulator) hit localhost.
// Release builds (archived for Appetize / TestFlight) hit the public Render URL.
// To rotate the production URL, edit the string below and rebuild Release.
#if DEBUG
private let baseURL = "http://localhost:8080"
#else
private let baseURL = "https://tiktok-trends-api.onrender.com"
#endif

@Observable
final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Injected by AuthManager after login
    var bearerToken: String?

    // Called on 401 — injected by AuthManager
    var onUnauthorized: (() -> Void)?

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)

        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601

        self.encoder = JSONEncoder()
        self.encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Generic request

    func request<T: Decodable>(_ endpoint: APIEndpoint, body: (some Encodable)? = nil as String?) async throws -> T {
        let urlRequest = try buildRequest(endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)
        try handleHTTPResponse(response, data: data)
        return try decode(data)
    }

    // Fire-and-forget (DELETE, etc.)
    func requestVoid(_ endpoint: APIEndpoint, body: (some Encodable)? = nil as String?) async throws {
        let urlRequest = try buildRequest(endpoint, body: body)
        let (data, response) = try await session.data(for: urlRequest)
        try handleHTTPResponse(response, data: data)
    }

    // MARK: - Build URLRequest

    private func buildRequest(_ endpoint: APIEndpoint, body: (some Encodable)?) throws -> URLRequest {
        var components = URLComponents(string: baseURL + endpoint.path)!
        if let items = endpoint.queryItems { components.queryItems = items }

        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method.rawValue
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = bearerToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try encoder.encode(body)
        }

        return req
    }

    // MARK: - Response handling

    private func handleHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299: return
        case 401:
            onUnauthorized?()
            throw APIError.unauthorized
        case 404:
            throw APIError.notFound
        case 429:
            throw APIError.rateLimited
        case 500...599:
            let msg = (try? decoder.decode(ServerErrorResponse.self, from: data))?.error ?? "Internal server error"
            throw APIError.serverError(msg)
        default:
            throw APIError.unknown(http.statusCode)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

// Shape returned by Spring Boot's GlobalExceptionHandler
private struct ServerErrorResponse: Decodable {
    let error: String?
    let message: String?
}

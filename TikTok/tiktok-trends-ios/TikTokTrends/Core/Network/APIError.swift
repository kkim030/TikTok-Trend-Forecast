import Foundation

enum APIError: LocalizedError {
    case unauthorized
    case notFound
    case serverError(String)
    case networkError(Error)
    case decodingError(Error)
    case rateLimited
    case unknown(Int)

    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Your session has expired. Please log in again."
        case .notFound:
            return "The requested resource was not found."
        case .serverError(let msg):
            return msg
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .decodingError:
            return "Failed to read server response."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .unknown(let code):
            return "Unexpected error (HTTP \(code))."
        }
    }
}

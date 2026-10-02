import Foundation

/// Failures when calling TypeSafe.
///
/// Cases carry status codes only. The server's error text is never kept, because it
/// could echo the API key or the sentence that was read, and it must not reach the screen.
public enum TypeSafeError: Error, Equatable, Sendable {
    /// No key saved in the Keychain yet.
    case missingAPIKey
    /// 401 or 403: the key is wrong, revoked, or lacks permission.
    case unauthorized
    /// 400 or 422: the request body failed validation.
    case invalidRequest(status: Int)
    /// 429 after all retries.
    case rateLimited
    /// 529 after all retries.
    case overloaded
    /// Any other non-2xx status.
    case server(status: Int)
    case offline
    case timeout
    case network
    /// The response was not the JSON shape we expected.
    case invalidResponse
}

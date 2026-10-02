import Foundation

/// Sends one HTTP request. Swappable so tests never touch the network.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    /// Ephemeral session: nothing about the user's text is cached on disk.
    public init(session: URLSession = URLSession(configuration: .ephemeral)) {
        self.session = session
    }

    public func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw TypeSafeError.invalidResponse }
        return (data, http)
    }
}

/// Minimal client for TypeSafe's System One endpoint.
///
/// The API key is read from `apiKeyProvider` (the Keychain in the app) for every call,
/// placed only in the `Authorization` header, and never logged or put into an error.
public struct TypeSafeClient: Sendable {
    public static let endpoint = URL(string: "https://api.typesafe.ai/v1/systemone")!

    public typealias APIKeyProvider = @Sendable () throws -> String?
    public typealias Sleeper = @Sendable (_ seconds: Double) async throws -> Void

    private static let maxRetryAfterSeconds = 5.0

    private let apiKeyProvider: APIKeyProvider
    private let transport: any HTTPTransport
    private let maxRetries: Int
    private let timeout: TimeInterval
    private let sleep: Sleeper

    public init(
        apiKeyProvider: @escaping APIKeyProvider,
        transport: any HTTPTransport = URLSessionTransport(),
        maxRetries: Int = 2,
        timeout: TimeInterval = 15,
        sleep: @escaping Sleeper = { seconds in
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        }
    ) {
        self.apiKeyProvider = apiKeyProvider
        self.transport = transport
        self.maxRetries = maxRetries
        self.timeout = timeout
        self.sleep = sleep
    }

    public func evaluate(_ body: SystemOneRequest) async throws -> SystemOneResponse {
        let apiKey = try apiKeyProvider()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !apiKey.isEmpty else { throw TypeSafeError.missingAPIKey }

        let request = try makeURLRequest(body: body, apiKey: apiKey)
        var attempt = 0
        while true {
            try Task.checkCancellation()
            let (data, response) = try await send(request)
            switch response.statusCode {
            case 200..<300:
                return try decode(data)
            case 429, 529:
                // Documented as retryable with exponential backoff.
                guard attempt < maxRetries else {
                    throw response.statusCode == 429 ? TypeSafeError.rateLimited : TypeSafeError.overloaded
                }
                try await sleep(Self.retryDelay(for: response, attempt: attempt))
                attempt += 1
            default:
                throw Self.error(forStatus: response.statusCode)
            }
        }
    }

    private func makeURLRequest(body: SystemOneRequest, apiKey: String) throws -> URLRequest {
        var request = URLRequest(url: Self.endpoint, timeoutInterval: timeout)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        request.httpBody = try encoder.encode(body)
        return request
    }

    private func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            return try await transport.send(request)
        } catch let error as URLError {
            switch error.code {
            case .timedOut:
                throw TypeSafeError.timeout
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                throw TypeSafeError.offline
            case .cancelled:
                throw CancellationError()
            default:
                throw TypeSafeError.network
            }
        }
    }

    private func decode(_ data: Data) throws -> SystemOneResponse {
        do {
            return try JSONDecoder().decode(SystemOneResponse.self, from: data)
        } catch {
            throw TypeSafeError.invalidResponse
        }
    }

    static func retryDelay(for response: HTTPURLResponse, attempt: Int) -> Double {
        if let header = response.value(forHTTPHeaderField: "Retry-After"),
           let seconds = Double(header.trimmingCharacters(in: .whitespaces)), seconds >= 0 {
            return min(seconds, maxRetryAfterSeconds)
        }
        return 0.5 * pow(2, Double(attempt))
    }

    /// Maps a status code to an error. The response body is deliberately ignored.
    static func error(forStatus status: Int) -> TypeSafeError {
        switch status {
        case 401, 403:
            return .unauthorized
        case 400, 422:
            return .invalidRequest(status: status)
        default:
            return .server(status: status)
        }
    }
}

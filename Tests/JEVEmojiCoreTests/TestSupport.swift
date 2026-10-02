import Foundation
@testable import JEVEmojiCore

/// Fake network. Returns canned responses in order and records every request.
actor MockTransport: HTTPTransport {
    struct Reply {
        let status: Int
        let body: String
        var headers: [String: String] = [:]
    }

    private var replies: [Reply]
    private(set) var requests: [URLRequest] = []

    init(_ replies: [Reply]) {
        self.replies = replies
    }

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        requests.append(request)
        let reply = replies.isEmpty ? Reply(status: 500, body: "{}") : replies.removeFirst()
        let response = HTTPURLResponse(
            url: request.url ?? TypeSafeClient.endpoint,
            statusCode: reply.status,
            httpVersion: "HTTP/1.1",
            headerFields: reply.headers
        )!
        return (Data(reply.body.utf8), response)
    }
}

actor SleepRecorder {
    private(set) var delays: [Double] = []

    func record(_ seconds: Double) {
        delays.append(seconds)
    }
}

/// Obviously fake value used only by tests.
let testAPIKey = "test-key-not-real"

func makeClient(_ transport: MockTransport, key: String? = testAPIKey, recorder: SleepRecorder = SleepRecorder()) -> TypeSafeClient {
    TypeSafeClient(
        apiKeyProvider: { key },
        transport: transport,
        maxRetries: 2,
        sleep: { seconds in await recorder.record(seconds) }
    )
}

/// A documented-shape response that gives `probabilities` to the emoji question.
func choiceResponse(_ probabilities: [String: Double]) -> String {
    let pairs = probabilities.map { "\"\($0.key)\": \($0.value)" }.joined(separator: ", ")
    return """
    {"model": "jev-1.13.0",
     "answers": {"emoji": {"type": "choice", "choice": "x", "probabilities": {\(pairs)}, "confidence": 0.7}},
     "usage": {"input_tokens": 10, "output_tokens": 2}}
    """
}

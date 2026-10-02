import Foundation
import Testing
@testable import JEVEmojiCore

struct TypeSafeClientTests {
    private let body = SystemOneRequest(
        state: TextState(text: "hi", kind: "search_query"),
        model: "jev-latest",
        questions: ["emoji": ChoiceQuestion(instructions: "Pick", criteria: ["tada": "🎉"])]
    )

    @Test func sendsBearerKeyToSystemOneEndpoint() async throws {
        let transport = MockTransport([.init(status: 200, body: choiceResponse(["tada": 1]))])
        _ = try await makeClient(transport).evaluate(body)

        let request = try #require(await transport.requests.first)
        #expect(request.url == URL(string: "https://api.typesafe.ai/v1/systemone"))
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer \(testAPIKey)")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    }

    @Test func missingKeyFailsWithoutNetworkCall() async throws {
        let transport = MockTransport([])
        await #expect(throws: TypeSafeError.missingAPIKey) {
            _ = try await makeClient(transport, key: nil).evaluate(body)
        }
        #expect(await transport.requests.isEmpty)
    }

    @Test func blankKeyCountsAsMissing() async throws {
        let transport = MockTransport([])
        await #expect(throws: TypeSafeError.missingAPIKey) {
            _ = try await makeClient(transport, key: "  \n").evaluate(body)
        }
    }

    @Test func retriesRateLimitHonoringRetryAfter() async throws {
        let recorder = SleepRecorder()
        let transport = MockTransport([
            .init(status: 429, body: "{}", headers: ["Retry-After": "2"]),
            .init(status: 200, body: choiceResponse(["tada": 1]))
        ])
        let response = try await makeClient(transport, recorder: recorder).evaluate(body)
        #expect(response.model == "jev-1.13.0")
        #expect(await recorder.delays == [2])
        #expect(await transport.requests.count == 2)
    }

    @Test func givesUpAfterMaxRetries() async throws {
        let recorder = SleepRecorder()
        let transport = MockTransport(Array(repeating: .init(status: 529, body: "{}"), count: 3))
        await #expect(throws: TypeSafeError.overloaded) {
            _ = try await makeClient(transport, recorder: recorder).evaluate(body)
        }
        #expect(await transport.requests.count == 3)
        #expect(await recorder.delays == [0.5, 1.0])
    }

    @Test func mapsStatusCodes() {
        #expect(TypeSafeClient.error(forStatus: 401) == .unauthorized)
        #expect(TypeSafeClient.error(forStatus: 422) == .invalidRequest(status: 422))
        #expect(TypeSafeClient.error(forStatus: 500) == .server(status: 500))
    }

    @Test func serverErrorTextNeverReachesTheScreen() async throws {
        let sentence = "오늘 너무 행복한 하루"
        let echoed = #"{"detail":"bad key \#(testAPIKey) for text \#(sentence)"}"#
        for status in [400, 422, 500] {
            let transport = MockTransport([.init(status: status, body: echoed)])
            do {
                _ = try await makeClient(transport).evaluate(body)
                Issue.record("Expected an error for status \(status)")
            } catch {
                let problem = UserFacingProblem(error: error)
                let shown = [problem.title, problem.reason, problem.nextStep].joined(separator: " ")
                #expect(!shown.contains(testAPIKey))
                #expect(!shown.contains(sentence))
                #expect(!"\(error)".contains(testAPIKey))
            }
        }
    }

    @Test func malformedJSONIsInvalidResponse() async throws {
        let transport = MockTransport([.init(status: 200, body: "not json")])
        await #expect(throws: TypeSafeError.invalidResponse) {
            _ = try await makeClient(transport).evaluate(body)
        }
    }
}

import Foundation
import Testing
@testable import JEVEmojiCore

struct RecommenderTests {
    private let catalog = (1...12).map { EmojiCandidate("e\($0)", "E\($0)", "meaning \($0)", "뜻 \($0)") }

    private func recommender(_ transport: MockTransport) -> JevEmojiRecommender {
        JevEmojiRecommender(client: makeClient(transport), catalog: catalog)
    }

    @Test func buildsOneChoiceQuestionOverWholeCatalog() throws {
        let request = try recommender(MockTransport([])).makeRequest(for: "  너무  기뻐요 ", source: .cursorContext)
        #expect(request.model == "jev-latest")
        #expect(request.state.text == "너무 기뻐요")
        #expect(request.state.kind == "text_near_cursor")
        let question = try #require(request.questions[JevEmojiRecommender.questionID])
        #expect(question.type == "choice")
        #expect(Set(question.criteria.keys) == Set(catalog.map(\.id)))
    }

    @Test func limitsStateTo140Characters() throws {
        let long = String(repeating: "가", count: 300)
        let request = try recommender(MockTransport([])).makeRequest(for: long, source: .searchQuery)
        #expect(request.state.text.count == 140)
    }

    @Test func rejectsEmptyText() {
        #expect(throws: RecommendationInputError.emptyText) {
            _ = try recommender(MockTransport([])).makeRequest(for: "   ", source: .searchQuery)
        }
    }

    /// Every catalog option scored, like a real Choice answer; unspecified ones get 0.
    private func distribution(_ top: [String: Double]) -> [String: Double] {
        Dictionary(uniqueKeysWithValues: catalog.map { ($0.id, top[$0.id] ?? 0) })
    }

    @Test func ranksTopTenByProbabilityWithCatalogOrderAsTieBreaker() throws {
        let ranked = try recommender(MockTransport([])).rank(probabilities: distribution(["e12": 0.5, "e3": 0.3, "e7": 0.2]))
        #expect(ranked.count == 10)
        #expect(ranked.prefix(3).map(\.id) == ["e12", "e3", "e7"])
        // Remaining options have probability 0 and keep catalog order.
        #expect(ranked.dropFirst(3).map(\.id) == ["e1", "e2", "e4", "e5", "e6", "e8", "e9"])
    }

    @Test func returnsTenRecommendationsFromJev() async throws {
        let transport = MockTransport([.init(status: 200, body: choiceResponse(distribution(["e5": 0.6, "e2": 0.4])))])
        let result = try await recommender(transport).recommend(for: "생일 축하해", source: .searchQuery)
        #expect(result.items.count == 10)
        #expect(result.items.first?.emoji == "E5")
        #expect(result.confidence == 0.7)
        #expect(result.model == "jev-1.13.0")
    }

    @Test func missingAnswerIsInvalidResponse() async throws {
        let body = #"{"model":"jev-1.13.0","answers":{},"usage":null}"#
        let transport = MockTransport([.init(status: 200, body: body)])
        await #expect(throws: TypeSafeError.invalidResponse) {
            _ = try await recommender(transport).recommend(for: "hi", source: .searchQuery)
        }
    }

    @Test(arguments: [
        [String: Double](),                                     // no probabilities at all
        ["e1": 0.6, "e2": 0.4],                                 // fewer than 10 options scored
        ["e1": 1.0, "e2": 0, "e3": 0, "e4": 0, "e5": 0, "e6": 0, "e7": 0, "e8": 0, "e9": 0, "zzz": 0], // unknown id
        ["e1": .nan, "e2": 0, "e3": 0, "e4": 0, "e5": 0, "e6": 0, "e7": 0, "e8": 0, "e9": 0, "e10": 0],
        ["e1": -0.5, "e2": 1.5, "e3": 0, "e4": 0, "e5": 0, "e6": 0, "e7": 0, "e8": 0, "e9": 0, "e10": 0],
        ["e1": 0, "e2": 0, "e3": 0, "e4": 0, "e5": 0, "e6": 0, "e7": 0, "e8": 0, "e9": 0, "e10": 0], // sums to 0
        ["e1": 1, "e2": 1, "e3": 0, "e4": 0, "e5": 0, "e6": 0, "e7": 0, "e8": 0, "e9": 0, "e10": 0]  // sums to 2
    ])
    func rejectsBrokenDistributions(probabilities: [String: Double]) {
        #expect(throws: TypeSafeError.invalidResponse) {
            _ = try recommender(MockTransport([])).rank(probabilities: probabilities)
        }
    }

    @Test func noProbabilitiesInResponseIsAnErrorNotDefaultEmoji() async throws {
        let body = #"{"model":"jev-1.13.0","answers":{"emoji":{"type":"choice","choice":"e1","confidence":0.9}}}"#
        let transport = MockTransport([.init(status: 200, body: body)])
        await #expect(throws: TypeSafeError.invalidResponse) {
            _ = try await recommender(transport).recommend(for: "hi", source: .searchQuery)
        }
    }

    @Test func wrongAnswerTypeIsInvalidResponse() async throws {
        let body = #"{"model":"jev-1.13.0","answers":{"emoji":{"type":"noul","noul":0.9}}}"#
        let transport = MockTransport([.init(status: 200, body: body)])
        await #expect(throws: TypeSafeError.invalidResponse) {
            _ = try await recommender(transport).recommend(for: "hi", source: .searchQuery)
        }
    }
}

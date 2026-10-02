import Foundation

/// Where the text came from. Sent to Jev as `state.kind`.
public enum TextSource: String, Sendable {
    case cursorContext = "text_near_cursor"
    case searchQuery = "search_query"
}

public struct EmojiRecommendation: Identifiable, Equatable, Sendable {
    public let id: String
    public let emoji: String
    public let meaning: String
    public let probability: Double

    public init(id: String, emoji: String, meaning: String, probability: Double) {
        self.id = id
        self.emoji = emoji
        self.meaning = meaning
        self.probability = probability
    }
}

public struct RecommendationResult: Equatable, Sendable {
    public let items: [EmojiRecommendation]
    /// Jev's own certainty about its top pick (0 to 1).
    public let confidence: Double?
    /// Versioned model id that answered, useful when reporting issues.
    public let model: String
}

public enum RecommendationInputError: Error, Equatable, Sendable {
    case emptyText
}

public protocol EmojiRecommending: Sendable {
    func recommend(for text: String, source: TextSource) async throws -> RecommendationResult
}

/// Asks Jev one Choice question over the whole emoji catalog, then keeps the
/// 10 options with the highest probability.
///
/// A Choice answer returns a probability for every option, so a single request
/// is enough to rank all candidates (the same idea as TypeSafe's line search cookbook).
public struct JevEmojiRecommender: EmojiRecommending {
    public static let resultCount = 10
    public static let questionID = "emoji"
    public static let defaultModel = "jev-latest"

    private let client: TypeSafeClient
    private let catalog: [EmojiCandidate]
    private let model: String

    public init(client: TypeSafeClient, catalog: [EmojiCandidate] = EmojiCatalog.all, model: String = defaultModel) {
        self.client = client
        self.catalog = Array(catalog.prefix(EmojiCatalog.maxChoiceOptions))
        self.model = model
    }

    public func recommend(for text: String, source: TextSource) async throws -> RecommendationResult {
        let request = try makeRequest(for: text, source: source)
        let response = try await client.evaluate(request)
        guard let answer = response.answers[Self.questionID],
              answer.type == "choice",
              let probabilities = answer.probabilities else {
            throw TypeSafeError.invalidResponse
        }
        return RecommendationResult(
            items: try rank(probabilities: probabilities),
            confidence: answer.confidence,
            model: response.model
        )
    }

    public func makeRequest(for text: String, source: TextSource) throws -> SystemOneRequest {
        let cleaned = ContextExtractor.normalized(text, limit: ContextExtractor.defaultLimit)
        guard !cleaned.isEmpty else { throw RecommendationInputError.emptyText }

        let criteria = Dictionary(catalog.map { ($0.id, $0.criterion) }, uniquingKeysWith: { first, _ in first })
        let question = ChoiceQuestion(instructions: Self.instructions(for: source), criteria: criteria)
        return SystemOneRequest(
            state: TextState(text: cleaned, kind: source.rawValue),
            model: model,
            questions: [Self.questionID: question]
        )
    }

    /// Highest probability first; catalog order breaks ties.
    ///
    /// Only options Jev actually scored are ranked. A missing, partial, or malformed
    /// distribution throws `invalidResponse` instead of showing default emoji as if it worked.
    public func rank(probabilities: [String: Double]) throws -> [EmojiRecommendation] {
        guard Self.isValidDistribution(probabilities, knownIDs: Set(catalog.map(\.id))) else {
            throw TypeSafeError.invalidResponse
        }
        return catalog.enumerated()
            .compactMap { entry -> (index: Int, candidate: EmojiCandidate, probability: Double)? in
                guard let probability = probabilities[entry.element.id] else { return nil }
                return (entry.offset, entry.element, probability)
            }
            .sorted { lhs, rhs in
                lhs.probability != rhs.probability ? lhs.probability > rhs.probability : lhs.index < rhs.index
            }
            .prefix(Self.resultCount)
            .map {
                EmojiRecommendation(
                    id: $0.candidate.id,
                    emoji: $0.candidate.emoji,
                    meaning: $0.candidate.meaning,
                    probability: $0.probability
                )
            }
    }

    /// Allowed rounding error for the SUM of all probabilities only.
    static let sumTolerance = 0.05

    /// A usable Choice distribution: only options we sent, at least 10 of them,
    /// every single value a real probability in 0...1 (no tolerance),
    /// a sum within `sumTolerance` of 1, and some positive mass.
    static func isValidDistribution(_ probabilities: [String: Double], knownIDs: Set<String>) -> Bool {
        guard probabilities.count >= resultCount,
              Set(probabilities.keys).isSubset(of: knownIDs),
              probabilities.values.allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
            return false
        }
        let total = probabilities.values.reduce(0, +)
        return abs(total - 1) <= sumTolerance && probabilities.values.contains { $0 > 0 }
    }

    static func instructions(for source: TextSource) -> String {
        switch source {
        case .cursorContext:
            return "Which emoji best fits the feeling and topic of `text`, a sentence the user is writing right now? `text` may be Korean."
        case .searchQuery:
            return "Which emoji best matches the search keyword in `text`? `text` may be Korean."
        }
    }
}

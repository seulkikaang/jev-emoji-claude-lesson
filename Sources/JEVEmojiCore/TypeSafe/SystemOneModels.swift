import Foundation

// Request and response shapes for `POST https://api.typesafe.ai/v1/systemone`.
// Source: https://docs.typesafe.ai/api (checked 2026-10-03).

/// Top-level request body: a `state`, a `model`, and a map of named questions.
public struct SystemOneRequest: Encodable, Equatable, Sendable {
    public let state: TextState
    public let model: String
    public let questions: [String: ChoiceQuestion]

    public init(state: TextState, model: String, questions: [String: ChoiceQuestion]) {
        self.state = state
        self.model = model
        self.questions = questions
    }
}

/// Structured state. Questions refer to its fields by name in backticks, e.g. `text`.
public struct TextState: Encodable, Equatable, Sendable {
    public let text: String
    public let kind: String

    public init(text: String, kind: String) {
        self.text = text
        self.kind = kind
    }
}

/// A Choice question: pick one option from `criteria` (max 255 options).
public struct ChoiceQuestion: Encodable, Equatable, Sendable {
    public let type: String
    public let instructions: String
    public let criteria: [String: String]

    public init(instructions: String, criteria: [String: String]) {
        self.type = "choice"
        self.instructions = instructions
        self.criteria = criteria
    }
}

public struct SystemOneResponse: Decodable, Equatable, Sendable {
    /// The versioned model that answered, e.g. "jev-1.13.0".
    public let model: String
    public let answers: [String: ChoiceAnswer]
    public let usage: Usage?
}

/// A Choice answer. Fields are optional so other answer types still decode.
public struct ChoiceAnswer: Decodable, Equatable, Sendable {
    public let type: String
    public let choice: String?
    /// Every option mapped to its probability. Values sum to 1.
    public let probabilities: [String: Double]?
    public let confidence: Double?
}

public struct Usage: Decodable, Equatable, Sendable {
    public let inputTokens: Int?
    public let outputTokens: Int?

    enum CodingKeys: String, CodingKey {
        case inputTokens = "input_tokens"
        case outputTokens = "output_tokens"
    }
}

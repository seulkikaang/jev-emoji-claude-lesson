import Foundation

/// One emoji that Jev can choose. `id` is the Choice option key sent to TypeSafe.
public struct EmojiCandidate: Equatable, Sendable {
    public let id: String
    public let emoji: String
    /// English meaning. English is Jev's strongest language, so it leads the description.
    public let meaning: String
    /// Korean keywords so Korean sentences map to the right option.
    public let keywordsKo: String

    public init(_ id: String, _ emoji: String, _ meaning: String, _ keywordsKo: String) {
        self.id = id
        self.emoji = emoji
        self.meaning = meaning
        self.keywordsKo = keywordsKo
    }

    /// Rubric text for this option inside the Choice question's `criteria`.
    public var criterion: String {
        "\(emoji) \(meaning) (\(keywordsKo))"
    }
}

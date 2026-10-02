import Testing
@testable import JEVEmojiCore

struct EmojiCatalogTests {
    @Test func fitsInOneChoiceQuestion() {
        #expect(EmojiCatalog.all.count >= JevEmojiRecommender.resultCount)
        #expect(EmojiCatalog.all.count <= EmojiCatalog.maxChoiceOptions)
    }

    @Test func idsAreUnique() {
        let ids = EmojiCatalog.all.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func emojiAreUnique() {
        let emoji = EmojiCatalog.all.map(\.emoji)
        #expect(Set(emoji).count == emoji.count)
    }

    @Test func everyEntryHasEmojiMeaningAndKoreanKeywords() {
        for candidate in EmojiCatalog.all {
            #expect(!candidate.emoji.isEmpty)
            #expect(!candidate.meaning.isEmpty)
            #expect(!candidate.keywordsKo.isEmpty)
            #expect(candidate.criterion.hasPrefix(candidate.emoji))
        }
    }
}

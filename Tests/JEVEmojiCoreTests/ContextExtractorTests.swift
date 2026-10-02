import Testing
@testable import JEVEmojiCore

struct ContextExtractorTests {
    @Test func returnsShortSentenceAsIs() {
        let text = "오늘 정말 행복해"
        #expect(ContextExtractor.extract(from: text, cursorUTF16Offset: text.utf16.count) == text)
    }

    @Test func neverExceedsLimit() {
        let text = String(repeating: "가", count: 500)
        let result = ContextExtractor.extract(from: text, cursorUTF16Offset: text.utf16.count)
        #expect(result.count == ContextExtractor.defaultLimit)
    }

    @Test func startsAtSentenceBoundaryWhenTooLong() {
        let text = String(repeating: "a", count: 130) + ". 두 번째 문장입니다"
        let result = ContextExtractor.extract(from: text, cursorUTF16Offset: text.utf16.count)
        #expect(result == "두 번째 문장입니다")
    }

    @Test func includesRestOfCurrentSentenceAfterCursor() {
        let before = "나는 커피를 좋아해. 오늘은 "
        let text = before + "비가 와서 기분이 좋아. 내일은"
        let result = ContextExtractor.extract(from: text, cursorUTF16Offset: before.utf16.count)
        #expect(result == "나는 커피를 좋아해. 오늘은 비가 와서 기분이 좋아.")
    }

    @Test func usesCurrentLineOnly() {
        let text = "이전 줄\n현재 줄 입력중"
        #expect(ContextExtractor.extract(from: text, cursorUTF16Offset: text.utf16.count) == "현재 줄 입력중")
    }

    @Test func fallsBackToPreviousLineOnEmptyLine() {
        let text = "첫 줄 내용\n"
        #expect(ContextExtractor.extract(from: text, cursorUTF16Offset: text.utf16.count) == "첫 줄 내용")
    }

    @Test func clampsOutOfRangeCursor() {
        #expect(ContextExtractor.extract(from: "hello", cursorUTF16Offset: 999) == "hello")
        #expect(ContextExtractor.extract(from: "hello", cursorUTF16Offset: -5) == "hello")
    }

    @Test func countsEmojiAsSingleCharacters() {
        let text = String(repeating: "😀", count: 200)
        let result = ContextExtractor.extract(from: text, cursorUTF16Offset: text.utf16.count)
        #expect(result.count == ContextExtractor.defaultLimit)
        #expect(result.allSatisfy { $0 == "😀" })
    }

    @Test func emptyTextReturnsEmpty() {
        #expect(ContextExtractor.extract(from: "", cursorUTF16Offset: 0).isEmpty)
    }

    @Test func normalizedCollapsesWhitespace() {
        #expect(ContextExtractor.normalized("  a \n\n b\tc  ") == "a b c")
    }
}

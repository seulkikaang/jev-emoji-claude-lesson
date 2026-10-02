import Foundation

/// Picks the sentence around the text cursor, capped at `limit` characters.
///
/// Text before the cursor has priority because that is what the user just wrote.
/// Any room left is filled with the rest of the current sentence after the cursor.
public enum ContextExtractor {
    public static let defaultLimit = 140

    private static let sentenceTerminators: Set<Character> = [".", "!", "?", "。", "！", "？", "…"]

    /// - Parameters:
    ///   - text: The whole (or a window of the) text field value.
    ///   - cursorUTF16Offset: Insertion point as reported by macOS Accessibility (UTF-16 units).
    ///   - limit: Maximum number of characters (grapheme clusters) to return.
    public static func extract(from text: String, cursorUTF16Offset: Int, limit: Int = defaultLimit) -> String {
        guard limit > 0, !text.isEmpty else { return "" }

        let clampedOffset = min(max(cursorUTF16Offset, 0), text.utf16.count)
        let cursor = String.Index(utf16Offset: clampedOffset, in: text)

        var before = currentLine(endingAt: cursor, in: text)
        let after = restOfSentence(startingAt: cursor, in: text, limit: limit)

        if isBlank(before), isBlank(after) {
            // Cursor sits on an empty line: use the line the user just finished.
            before = lastNonEmptyLine(before: cursor, in: text)
        }

        let head = trimToLimit(before, limit: limit)
        let remaining = limit - head.count
        let tail = remaining > 0 ? String(after.prefix(remaining)) : ""
        return normalized(head + tail, limit: limit)
    }

    /// Collapses whitespace runs into single spaces and caps the length.
    public static func normalized(_ text: String, limit: Int = defaultLimit) -> String {
        let collapsed = text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
        return String(collapsed.prefix(max(limit, 0)))
    }

    private static func currentLine(endingAt cursor: String.Index, in text: String) -> String {
        let prefix = text[..<cursor]
        guard let newline = prefix.lastIndex(where: { $0.isNewline }) else { return String(prefix) }
        return String(prefix[prefix.index(after: newline)...])
    }

    private static func restOfSentence(startingAt cursor: String.Index, in text: String, limit: Int) -> String {
        var result = ""
        var count = 0
        for character in text[cursor...] {
            if character.isNewline || count >= limit { break }
            result.append(character)
            count += 1
            if sentenceTerminators.contains(character) { break }
        }
        return result
    }

    private static func lastNonEmptyLine(before cursor: String.Index, in text: String) -> String {
        let lines = text[..<cursor].split(whereSeparator: { $0.isNewline })
        return lines.last(where: { !isBlank(String($0)) }).map(String.init) ?? ""
    }

    private static func trimToLimit(_ text: String, limit: Int) -> String {
        guard text.count > limit else { return text }
        let window = String(text.suffix(limit))

        // Start at a sentence boundary so the context reads naturally.
        if let boundary = window.firstIndex(where: { sentenceTerminators.contains($0) }) {
            let candidate = window[window.index(after: boundary)...].trimmingCharacters(in: .whitespaces)
            if !candidate.isEmpty { return candidate }
        }
        // Otherwise avoid starting in the middle of a word.
        if let space = window.firstIndex(of: " ") {
            let candidate = String(window[window.index(after: space)...])
            if !isBlank(candidate) { return candidate }
        }
        return window
    }

    private static func isBlank(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

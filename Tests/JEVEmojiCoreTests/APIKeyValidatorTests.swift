import Testing
@testable import JEVEmojiCore

struct APIKeyValidatorTests {
    @Test func trimsSurroundingWhitespace() throws {
        #expect(try APIKeyValidator.validate("  abc123\n") == "abc123")
    }

    @Test func rejectsEmpty() {
        #expect(throws: APIKeyValidationError.empty) { try APIKeyValidator.validate("   ") }
    }

    @Test func rejectsInnerWhitespace() {
        #expect(throws: APIKeyValidationError.containsWhitespace) { try APIKeyValidator.validate("abc 123") }
    }

    @Test func rejectsOverlyLongKeys() {
        let key = String(repeating: "a", count: APIKeyValidator.maxLength + 1)
        #expect(throws: APIKeyValidationError.tooLong) { try APIKeyValidator.validate(key) }
    }
}

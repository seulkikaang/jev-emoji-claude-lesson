import Testing
@testable import JEVEmojiCore

struct InsertionGuardTests {
    private func check(
        originalPID: Int32? = 42,
        fieldKnown: Bool = true,
        running: Bool = true,
        currentPID: Int32? = 42,
        sameField: Bool = true,
        secure: Bool = false
    ) -> FocusCheck {
        FocusCheck(
            originalPID: originalPID,
            originalFieldKnown: fieldKnown,
            originalAppRunning: running,
            contextWasRead: true,
            currentPID: currentPID,
            isSameField: sameField,
            currentFieldIsSecure: secure,
            currentFieldIsEditable: true,
            isSameSelection: true
        )
    }

    @Test func allowsTypingWhenNothingChanged() {
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check()) == nil)
    }

    @Test func blocksWithoutPermission() {
        #expect(InsertionGuard.block(isAccessibilityGranted: false, check: check()) == .accessibilityNotGranted)
    }

    @Test func blocksWhenFieldWasNeverKnown() {
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(fieldKnown: false)) == .noOriginalField)
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(originalPID: nil)) == .noOriginalField)
    }

    @Test func blocksWhenAppClosed() {
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(running: false)) == .appClosed)
    }

    @Test func blocksWhenAnotherAppIsInFront() {
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(currentPID: 7)) == .appChanged)
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(currentPID: nil)) == .appChanged)
    }

    @Test func blocksWhenFieldChanged() {
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(sameField: false)) == .fieldChanged)
    }

    @Test func neverTypesIntoPasswordFields() {
        #expect(InsertionGuard.block(isAccessibilityGranted: true, check: check(secure: true)) == .secureField)
    }

    @Test(arguments: [
        InsertionBlock.accessibilityNotGranted, .noOriginalField, .appClosed,
        .appChanged, .fieldChanged, .secureField, .keystrokeFailed
    ])
    func everyBlockExplainsClipboardFallback(block: InsertionBlock) {
        let notice = block.clipboardNotice(emoji: "🎉")
        #expect(notice.contains("🎉"))
        #expect(notice.contains("⌘V"))
    }
}

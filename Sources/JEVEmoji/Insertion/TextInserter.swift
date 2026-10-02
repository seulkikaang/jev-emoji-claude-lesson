import AppKit
import CoreGraphics
import JEVEmojiCore

/// Puts the chosen emoji back into the input field the user was typing in.
///
/// Before typing it checks that the same app, field, and cursor selection are still there,
/// that the field accepts text, and that it is not a password field. After typing it reads
/// the field back; a sent key event alone is never treated as a finished insertion.
@MainActor
final class TextInserter {
    /// Time for the previous app to regain keyboard focus after the panel closes.
    private let refocusDelayNanoseconds: UInt64 = 150_000_000
    /// Time between attempts to read the emoji back from the field.
    private let confirmDelayNanoseconds: UInt64 = 120_000_000
    private let confirmAttempts = 3

    /// Returns why typing is unsafe right now, or nil when every check passes.
    func check(_ target: InsertionTarget) -> InsertionBlock? {
        let isGranted = AccessibilityPermission.isGranted
        let currentApp = NSWorkspace.shared.frontmostApplication
        var isSameField = false
        var isSecure = false
        var isEditable: Bool?
        var isSameSelection = false

        if isGranted, let app = target.app, let field = target.field,
           currentApp?.processIdentifier == app.processIdentifier,
           let current = AXElement.focusedElement(ofPID: app.processIdentifier).element {
            isSameField = AXElement.isSameElement(current, field)
            isSecure = AXElement.isSecureField(current)
            isEditable = AXElement.isEditable(current)
            if let original = target.selection, let now = AXElement.selectedRange(current) {
                isSameSelection = original.location == now.location && original.length == now.length
            }
        }

        let focusCheck = FocusCheck(
            originalPID: target.app?.processIdentifier,
            originalFieldKnown: target.field != nil,
            originalAppRunning: target.app.map { !$0.isTerminated } ?? false,
            contextWasRead: target.contextWasRead,
            currentPID: currentApp?.processIdentifier,
            isSameField: isSameField,
            currentFieldIsSecure: isSecure,
            currentFieldIsEditable: isEditable,
            isSameSelection: isSameSelection
        )
        return InsertionGuard.block(isAccessibilityGranted: isGranted, check: focusCheck)
    }

    /// Waits for the original field to get keyboard focus back, checks again, types,
    /// then confirms by reading the field. Never switches apps on the user's behalf.
    func typeWhenSafe(_ text: String, into target: InsertionTarget) async -> InsertionResult {
        try? await Task.sleep(nanoseconds: refocusDelayNanoseconds)
        if let block = check(target) { return .blocked(block) }
        guard let field = target.field, let selection = target.selection else {
            return .blocked(.noOriginalField)
        }
        guard postUnicodeKeystroke(text) else { return .blocked(.keystrokeFailed) }
        return await isTextPresent(text, in: field, at: selection.location) ? .inserted : .unconfirmed
    }

    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Reads the field back and checks that `text` now sits where the cursor was.
    private func isTextPresent(_ text: String, in field: AXUIElement, at location: Int) async -> Bool {
        let length = text.utf16.count
        for _ in 0..<confirmAttempts {
            try? await Task.sleep(nanoseconds: confirmDelayNanoseconds)
            if AXElement.string(field, in: CFRange(location: location, length: length)) == text {
                return true
            }
            if let value = AXElement.string(field, kAXValueAttribute),
               Self.utf16Slice(of: value, location: location, length: length) == text {
                return true
            }
        }
        return false
    }

    private static func utf16Slice(of value: String, location: Int, length: Int) -> String? {
        let units = value.utf16
        guard location >= 0, length > 0, location + length <= units.count else { return nil }
        let start = units.index(units.startIndex, offsetBy: location)
        let end = units.index(start, offsetBy: length)
        return String(decoding: units[start..<end], as: UTF16.self)
    }

    private func postUnicodeKeystroke(_ text: String) -> Bool {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false) else {
            return false
        }
        let units = Array(text.utf16)
        units.withUnsafeBufferPointer { buffer in
            keyDown.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
            keyUp.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: buffer.baseAddress)
        }
        // The user may still be holding ⌘ from ⌘1; send the emoji without modifiers.
        keyDown.flags = []
        keyUp.flags = []
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }
}

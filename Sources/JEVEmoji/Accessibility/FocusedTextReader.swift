import AppKit
import ApplicationServices
import JEVEmojiCore

/// The app, input field, and cursor selection captured when the shortcut was pressed.
/// The emoji goes back there only if all of them are still the same.
struct InsertionTarget {
    let app: NSRunningApplication?
    let field: AXUIElement?
    let selection: CFRange?
    /// The sentence around the cursor was read. Fields we could not read are never typed into.
    let contextWasRead: Bool

    static var none: InsertionTarget {
        InsertionTarget(app: nil, field: nil, selection: nil, contextWasRead: false)
    }
}

struct ContextCapture {
    let target: InsertionTarget
    let result: Result<String, ContextReadFailure>
}

/// Reads up to 140 characters around the text cursor of the frontmost app
/// through the macOS Accessibility API. It only reads; it never changes the other app.
@MainActor
final class FocusedTextReader {
    /// UTF-16 units read on each side of the cursor in long documents.
    private let windowRadius = 400
    /// Above this length, read only a window around the cursor instead of the whole value.
    private let fullReadLimit = 4_000

    func capture() -> ContextCapture {
        let frontmost = NSWorkspace.shared.frontmostApplication
        let isSelf = frontmost?.processIdentifier == ProcessInfo.processInfo.processIdentifier
        guard let app = isSelf ? nil : frontmost else {
            return ContextCapture(target: .none, result: .failure(.noFrontmostApp))
        }
        guard AccessibilityPermission.isGranted else {
            let target = InsertionTarget(app: app, field: nil, selection: nil, contextWasRead: false)
            return ContextCapture(target: target, result: .failure(.accessibilityNotGranted))
        }

        let appName = app.localizedName ?? "현재 앱"
        let (focusError, focused) = AXElement.focusedElement(ofPID: app.processIdentifier)
        guard let focused else {
            let failure: ContextReadFailure = focusError == .cannotComplete
                ? .timedOut(appName: appName)
                : .noFocusedElement(appName: appName)
            let target = InsertionTarget(app: app, field: nil, selection: nil, contextWasRead: false)
            return ContextCapture(target: target, result: .failure(failure))
        }

        let selection = AXElement.selectedRange(focused)
        let result = readContext(from: focused, selection: selection, appName: appName)
        let wasRead: Bool
        if case .success = result { wasRead = true } else { wasRead = false }
        let target = InsertionTarget(app: app, field: focused, selection: selection, contextWasRead: wasRead)
        return ContextCapture(target: target, result: result)
    }

    private func readContext(
        from focused: AXUIElement,
        selection: CFRange?,
        appName: String
    ) -> Result<String, ContextReadFailure> {
        if AXElement.isSecureField(focused) {
            return .failure(.secureField)
        }

        // Highlighted text wins: the user marked exactly what the emoji is about.
        if let selected = AXElement.string(focused, kAXSelectedTextAttribute) {
            let context = ContextExtractor.normalized(selected)
            if !context.isEmpty { return .success(context) }
        }

        guard let selection,
              let around = textAroundCursor(focused, cursor: selection.location) else {
            return .failure(.notEditableText(appName: appName))
        }

        let context = ContextExtractor.extract(from: around.text, cursorUTF16Offset: around.cursor)
        return context.isEmpty ? .failure(.emptyText) : .success(context)
    }

    private func textAroundCursor(_ element: AXUIElement, cursor: Int) -> (text: String, cursor: Int)? {
        if let total = AXElement.int(element, kAXNumberOfCharactersAttribute), total > fullReadLimit {
            let start = max(0, min(cursor, total) - windowRadius)
            let length = min(total - start, windowRadius * 2)
            if let text = AXElement.string(element, in: CFRange(location: start, length: length)) {
                return (text, cursor - start)
            }
        }
        guard let value = AXElement.string(element, kAXValueAttribute) else { return nil }
        return (value, cursor)
    }
}

import Foundation

/// Why the text around the cursor could not be read from the previous app.
public enum ContextReadFailure: Error, Equatable, Sendable {
    /// macOS Accessibility permission is off for this app.
    case accessibilityNotGranted
    /// There was no other app in front when the shortcut was pressed.
    case noFrontmostApp
    /// The app did not report a focused input field.
    case noFocusedElement(appName: String)
    /// Password fields are never read.
    case secureField
    /// The focused element does not expose its text (some browsers and Electron apps).
    case notEditableText(appName: String)
    /// The field is empty, so there is nothing to recommend from.
    case emptyText
    /// The app did not answer the Accessibility request in time.
    case timedOut(appName: String)
}

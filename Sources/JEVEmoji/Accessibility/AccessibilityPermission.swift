import AppKit
import ApplicationServices

/// macOS "Accessibility" permission. Needed to read the text near the cursor
/// and to type the chosen emoji into the previous app. The user grants it in System Settings.
enum AccessibilityPermission {
    private static let settingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
    )

    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system prompt (which also adds this app to the list) and opens the settings pane.
    /// Only called when the user presses a button.
    static func requestAccess() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        if !AXIsProcessTrustedWithOptions(options) {
            openSystemSettings()
        }
    }

    static func openSystemSettings() {
        guard let settingsURL else { return }
        NSWorkspace.shared.open(settingsURL)
    }
}

import AppKit
import SwiftUI
import JEVEmojiCore

/// Creates the settings window once and brings it to the front on request.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {
    private let viewModel: SettingsViewModel
    private var window: NSWindow?

    init(keyStore: any APIKeyStoring) {
        viewModel = SettingsViewModel(keyStore: keyStore)
        super.init()
    }

    func show() {
        viewModel.refresh()
        let window = self.window ?? makeWindow()
        self.window = window
        // A menu bar app has to activate itself before its window can come forward.
        NSApp.activate()
        window.makeKeyAndOrderFront(nil)
    }

    private func makeWindow() -> NSWindow {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView(model: viewModel)))
        window.title = "JEV 이모지 설정"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.center()
        window.delegate = self
        return window
    }

    /// Give focus back to the app the user was in, so the next ⌥⌘E reads that app.
    func windowWillClose(_ notification: Notification) {
        NSApp.hide(nil)
    }
}

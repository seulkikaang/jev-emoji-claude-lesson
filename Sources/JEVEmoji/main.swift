import AppKit

// Entry point. `.accessory` keeps the app out of the Dock: it lives only in the menu bar.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    // NSApplication holds its delegate weakly; keep it alive for the app's whole life.
    withExtendedLifetime(delegate) {
        app.run()
    }
}

import AppKit

/// Floating, borderless window that takes keyboard input without activating this app.
///
/// `.nonactivatingPanel` keeps the user's app in front, so after the panel closes
/// the cursor is still in the original input field and the emoji can go right there.
final class RecommendationPanel: NSPanel {
    var onResignKey: (() -> Void)?
    var onCancel: (() -> Void)?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 320),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovableByWindowBackground = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        appearance = NSAppearance(named: .aqua)
        animationBehavior = .utilityWindow
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Clicking anywhere else closes the panel.
    override func resignKey() {
        super.resignKey()
        onResignKey?()
    }

    /// Esc
    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}

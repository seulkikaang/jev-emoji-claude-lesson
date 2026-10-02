import AppKit
import SwiftUI
import JEVEmojiCore

/// Shows and hides the recommendation panel and delivers the picked emoji
/// to the input field the user came from.
@MainActor
final class RecommendationPanelController {
    private let panel = RecommendationPanel()
    private let viewModel: RecommendationViewModel
    private let inserter: TextInserter
    private var target = InsertionTarget.none
    /// True while the panel is hidden for typing, so losing key focus does not reset it.
    private var isDelivering = false

    var isVisible: Bool { panel.isVisible }

    init(recommender: any EmojiRecommending, inserter: TextInserter, onOpenSettings: @escaping () -> Void) {
        self.inserter = inserter
        viewModel = RecommendationViewModel(recommender: recommender)
        panel.contentView = NSHostingView(rootView: RecommendationView(model: viewModel))

        viewModel.onClose = { [weak self] in self?.hide() }
        viewModel.onPick = { [weak self] emoji in self?.deliver(emoji) }
        viewModel.onOpenSettings = { [weak self] in
            self?.hide()
            onOpenSettings()
        }
        viewModel.onOpenAccessibilitySettings = { [weak self] in
            self?.hide()
            AccessibilityPermission.requestAccess()
        }
        panel.onResignKey = { [weak self] in
            guard let self, !self.isDelivering else { return }
            self.hide()
        }
        panel.onCancel = { [weak self] in self?.hide() }
    }

    func show(capture: ContextCapture) {
        target = capture.target
        viewModel.begin(with: capture.result)
        positionOnActiveScreen()
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        guard panel.isVisible else { return }
        panel.orderOut(nil)
        viewModel.reset()
    }

    private func deliver(_ emoji: String) {
        guard !isDelivering else { return }
        // First check while the panel is still open: same app, same field, not a password field.
        if let block = inserter.check(target) {
            showClipboardNotice(for: emoji, result: .blocked(block), reopen: false)
            return
        }

        let target = self.target
        isDelivering = true
        panel.orderOut(nil)
        Task { @MainActor [weak self, inserter] in
            // Second check happens inside, right before the keystroke is sent.
            let result = await inserter.typeWhenSafe(emoji, into: target)
            guard let self else { return }
            self.isDelivering = false
            if result == .inserted {
                self.viewModel.reset()
            } else {
                self.showClipboardNotice(for: emoji, result: result, reopen: true)
            }
        }
    }

    /// Copies the emoji and explains why it was not (or may not have been) typed and what to do next.
    private func showClipboardNotice(for emoji: String, result: InsertionResult, reopen: Bool) {
        inserter.copyToClipboard(emoji)
        viewModel.notice = result.notice(emoji: emoji)
        if reopen {
            positionOnActiveScreen()
            panel.makeKeyAndOrderFront(nil)
        }
    }

    private func positionOnActiveScreen() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return }

        panel.contentView?.layoutSubtreeIfNeeded()
        let size = panel.contentView?.fittingSize ?? panel.frame.size
        panel.setContentSize(size)
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY + visible.height * 0.12 - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }
}

import AppKit

/// The menu bar icon and its menu.
@MainActor
final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let onOpenPanel: () -> Void
    private let onOpenSettings: () -> Void

    init(onOpenPanel: @escaping () -> Void, onOpenSettings: @escaping () -> Void) {
        self.onOpenPanel = onOpenPanel
        self.onOpenSettings = onOpenSettings
        super.init()

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "JEV 이모지")
            image?.isTemplate = true
            button.image = image
            button.toolTip = "JEV 이모지 (⌥⌘E)"
        }
        statusItem.menu = makeMenu()
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let open = NSMenuItem(title: "이모지 추천 열기", action: #selector(openPanel), keyEquivalent: "e")
        open.keyEquivalentModifierMask = [.option, .command]
        open.target = self
        menu.addItem(open)

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "설정…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        let accessibility = NSMenuItem(
            title: "손쉬운 사용 권한 설정",
            action: #selector(openAccessibilitySettings),
            keyEquivalent: ""
        )
        accessibility.target = self
        menu.addItem(accessibility)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "JEV 이모지 종료", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func openPanel() {
        onOpenPanel()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func openAccessibilitySettings() {
        AccessibilityPermission.requestAccess()
    }

    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}

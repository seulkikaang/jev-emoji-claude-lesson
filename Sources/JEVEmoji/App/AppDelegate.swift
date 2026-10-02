import AppKit
import JEVEmojiCore

/// Wires everything together when the app starts.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private lazy var textReader = FocusedTextReader()
    private var statusBar: StatusBarController?
    private var hotKey: HotKeyManager?
    private var panelController: RecommendationPanelController?
    private var settingsController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let keyStore = KeychainAPIKeyStore()
        // The key is read from the Keychain at request time and kept nowhere else.
        let client = TypeSafeClient(apiKeyProvider: { try keyStore.readKey() })
        let recommender = JevEmojiRecommender(client: client)

        let settings = SettingsWindowController(keyStore: keyStore)
        settingsController = settings

        panelController = RecommendationPanelController(
            recommender: recommender,
            inserter: TextInserter(),
            onOpenSettings: { [weak settings] in settings?.show() }
        )

        statusBar = StatusBarController(
            onOpenPanel: { [weak self] in self?.togglePanel() },
            onOpenSettings: { [weak settings] in settings?.show() }
        )

        registerHotKey()

        // First launch without a key: open settings so the user knows where to put it.
        if (try? keyStore.hasKey()) != true {
            settings.show()
        }
    }

    private func registerHotKey() {
        let hotKey = HotKeyManager { [weak self] in
            // Carbon delivers hot key events on the main thread.
            MainActor.assumeIsolated { self?.togglePanel() }
        }
        do {
            try hotKey.register()
            self.hotKey = hotKey
        } catch {
            showHotKeyAlert()
        }
    }

    private func togglePanel() {
        guard let panelController else { return }
        if panelController.isVisible {
            panelController.hide()
        } else {
            // Read the text before the panel appears, while the user's app is still in front.
            panelController.show(capture: textReader.capture())
        }
    }

    private func showHotKeyAlert() {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = "⌥⌘E 단축키를 등록하지 못했어요"
        alert.informativeText = "다른 앱이 같은 단축키를 쓰고 있을 수 있어요. 메뉴 막대의 웃는 얼굴 아이콘에서 '이모지 추천 열기'를 눌러 쓰세요."
        alert.addButton(withTitle: "확인")
        alert.runModal()
    }
}

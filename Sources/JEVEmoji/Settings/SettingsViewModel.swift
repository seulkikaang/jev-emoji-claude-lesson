import Foundation
import JEVEmojiCore

/// Saves and deletes the TypeSafe API key in the Keychain and reports
/// Accessibility status. The saved key is never read back into the UI.
@MainActor
final class SettingsViewModel: ObservableObject {
    struct Status: Equatable {
        let text: String
        let isError: Bool
    }

    @Published var draftKey = ""
    @Published private(set) var hasStoredKey = false
    @Published private(set) var status: Status?
    @Published private(set) var isAccessibilityGranted = false

    private let keyStore: any APIKeyStoring

    init(keyStore: any APIKeyStoring) {
        self.keyStore = keyStore
    }

    func refresh() {
        draftKey = ""
        status = nil
        refreshAccessibility()
        do {
            hasStoredKey = try keyStore.hasKey()
        } catch {
            hasStoredKey = false
            status = Status(text: "키체인을 확인하지 못했어요. 키를 다시 저장해 보세요.", isError: true)
        }
    }

    func save() {
        do {
            try keyStore.saveKey(draftKey)
            hasStoredKey = true
            status = Status(text: "맥 키체인에 저장했어요. 이제 ⌥⌘E로 추천을 받을 수 있어요.", isError: false)
        } catch let error as APIKeyValidationError {
            status = Status(text: error.message, isError: true)
        } catch {
            status = Status(text: "키체인에 저장하지 못했어요. 맥 잠금을 풀고 다시 시도해 주세요.", isError: true)
        }
        // Do not keep the secret in memory longer than needed.
        draftKey = ""
    }

    func delete() {
        do {
            try keyStore.deleteKey()
            hasStoredKey = false
            status = Status(text: "저장된 키를 지웠어요.", isError: false)
        } catch {
            status = Status(text: "키를 지우지 못했어요. 다시 시도해 주세요.", isError: true)
        }
    }

    func clearDraft() {
        draftKey = ""
    }

    func refreshAccessibility() {
        isAccessibilityGranted = AccessibilityPermission.isGranted
    }

    func requestAccessibility() {
        AccessibilityPermission.requestAccess()
    }
}

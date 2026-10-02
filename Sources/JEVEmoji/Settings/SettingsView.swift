import SwiftUI

/// Settings window: TypeSafe API key, Accessibility permission, shortcut.
struct SettingsView: View {
    @ObservedObject var model: SettingsViewModel

    private static let consoleURL = URL(string: "https://console.typesafe.ai/")

    init(model: SettingsViewModel) {
        _model = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            apiKeySection
            Divider()
            accessibilitySection
            Divider()
            section(title: "단축키") {
                Text("⌥⌘E  추천 창 열기 · 닫기")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.ink)
            }
        }
        .padding(24)
        .frame(width: 460)
        .background(Theme.paper)
        .environment(\.colorScheme, .light)
        .onDisappear { model.clearDraft() }
    }

    private var apiKeySection: some View {
        section(title: "TypeSafe API 키") {
            Text("JEV 추천에 쓰는 키예요. 맥 키체인에만 저장하고, 저장한 뒤에는 화면이나 로그에 보여 주지 않아요.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkMuted)
                .fixedSize(horizontal: false, vertical: true)

            statusRow(isOn: model.hasStoredKey, text: model.hasStoredKey ? "저장된 키가 있어요" : "저장된 키가 없어요")

            SecureField("새 API 키 붙여 넣기", text: $model.draftKey)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.hairline, lineWidth: 1))
                .onSubmit { model.save() }

            HStack(spacing: 8) {
                PillButton(title: "키체인에 저장") { model.save() }
                    .disabled(model.draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                PillButton(title: "저장된 키 삭제", style: .outlined) { model.delete() }
                    .disabled(!model.hasStoredKey)
                Spacer()
                if let consoleURL = Self.consoleURL {
                    Link("키 발급받기", destination: consoleURL)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.pink)
                }
            }

            if let status = model.status {
                Text(status.text)
                    .font(.system(size: 12))
                    .foregroundStyle(status.isError ? Theme.pink : Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var accessibilitySection: some View {
        section(title: "손쉬운 사용 권한") {
            statusRow(isOn: model.isAccessibilityGranted, text: model.isAccessibilityGranted ? "켜져 있어요" : "꺼져 있어요")
            Text(
                model.isAccessibilityGranted
                    ? "커서 주변 문장을 읽고, 고른 이모지를 원래 입력칸에 바로 넣을 수 있어요."
                    : "켜야 커서 주변 문장을 읽고 이모지를 바로 넣을 수 있어요. 꺼져 있으면 검색어 추천과 클립보드 복사만 돼요."
            )
            .font(.system(size: 12))
            .foregroundStyle(Theme.inkMuted)
            .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                PillButton(title: "시스템 설정 열기") { model.requestAccessibility() }
                PillButton(title: "다시 확인", style: .outlined) { model.refreshAccessibility() }
            }
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.ink)
            content()
        }
    }

    private func statusRow(isOn: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOn ? Theme.pink : Theme.paper)
                .overlay(Circle().stroke(isOn ? Theme.pink : Theme.inkMuted, lineWidth: 1))
                .frame(width: 8, height: 8)
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.ink)
        }
    }
}

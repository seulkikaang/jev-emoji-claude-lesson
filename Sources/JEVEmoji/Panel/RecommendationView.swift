import SwiftUI
import JEVEmojiCore

/// Content of the small window: search field, the sentence that was read,
/// then 10 emoji, a loading line, or a problem card.
struct RecommendationView: View {
    @ObservedObject var model: RecommendationViewModel
    @FocusState private var searchFocused: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    init(model: RecommendationViewModel) {
        _model = ObservedObject(wrappedValue: model)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            searchField
            sourceLine
            content
                .frame(maxWidth: .infinity, minHeight: 140, alignment: .top)
            if let notice = model.notice {
                NoticeBanner(text: notice)
            }
            footer
        }
        .padding(16)
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous).fill(Theme.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous).stroke(Theme.hairline, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.panelCorner, style: .continuous))
        .environment(\.colorScheme, .light)
        .onAppear { searchFocused = true }
        .onChange(of: model.focusSearchRequest) { _, _ in searchFocused = true }
        .onExitCommand { model.close() }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle().fill(Theme.pink).frame(width: 8, height: 8)
            Text("JEV 이모지 추천")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            iconButton("gearshape", help: "설정") { model.openSettings() }
            iconButton("xmark", help: "닫기 (Esc)") { model.close() }
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(searchFocused ? Theme.pink : Theme.inkMuted)
            TextField("검색어 입력 후 Return (예: 축하, 피곤해)", text: $model.query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.ink)
                .focused($searchFocused)
                .onSubmit { model.submitQuery() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.paper))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(searchFocused ? Theme.pink : Theme.hairline, lineWidth: searchFocused ? 2 : 1)
        )
    }

    @ViewBuilder
    private var sourceLine: some View {
        if let source = model.sourceDescription {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(source.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.pink)
                Text(source.text)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkMuted)
                    .lineLimit(2)
                    .truncationMode(.head)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.phase {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small).tint(Theme.pink)
                Text("JEV가 어울리는 이모지를 고르는 중…")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 140)
        case .results(let items):
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    EmojiCell(item: item, shortcut: Self.shortcutKey(for: index)) { model.pick(item) }
                }
            }
        case .problem(let problem):
            ProblemCard(problem: problem) { model.perform($0) }
        }
    }

    private var footer: some View {
        Text("클릭하거나 ⌘1~⌘0으로 넣기 · 검색어 입력 후 Return · Esc 닫기")
            .font(.system(size: 10))
            .foregroundStyle(Theme.inkMuted)
    }

    private func iconButton(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.inkMuted)
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }

    /// 1...9 for the first nine results, 0 for the tenth.
    static func shortcutKey(for index: Int) -> Character {
        Character(String((index + 1) % 10))
    }
}

private struct EmojiCell: View {
    let item: EmojiRecommendation
    let shortcut: Character
    let action: () -> Void

    @State private var hovering = false

    init(item: EmojiRecommendation, shortcut: Character, action: @escaping () -> Void) {
        self.item = item
        self.shortcut = shortcut
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(item.emoji).font(.system(size: 30))
                Text("⌘\(String(shortcut))")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(hovering ? Theme.pink : Theme.inkMuted)
            }
            .frame(maxWidth: .infinity, minHeight: 64)
            .background(
                RoundedRectangle(cornerRadius: Theme.cellCorner).fill(hovering ? Theme.pinkWash : Theme.paper)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cellCorner)
                    .stroke(hovering ? Theme.pink : Theme.hairline, lineWidth: hovering ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.cellCorner))
        }
        .buttonStyle(.plain)
        .keyboardShortcut(KeyEquivalent(shortcut), modifiers: .command)
        .onHover { hovering = $0 }
        .help(item.meaning)
        .accessibilityLabel("\(item.emoji) \(item.meaning)")
    }
}

private struct ProblemCard: View {
    let problem: UserFacingProblem
    let onAction: (ProblemAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(Theme.pink)
                Text(problem.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.ink)
            }
            Text(problem.reason)
                .font(.system(size: 12))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("다음 행동")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.pink)
                Text(problem.nextStep)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 8) {
                ForEach(Array(problem.actions.enumerated()), id: \.element) { index, action in
                    PillButton(title: action.title, style: index == 0 ? .filled : .outlined) {
                        onAction(action)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.cellCorner).fill(Theme.pinkWash))
        .overlay(RoundedRectangle(cornerRadius: Theme.cellCorner).stroke(Theme.pink.opacity(0.35), lineWidth: 1))
    }
}

private struct NoticeBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: "doc.on.clipboard").foregroundStyle(Theme.pink)
            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Theme.pinkWash))
    }
}

extension ProblemAction {
    var title: String {
        switch self {
        case .openAppSettings: return "API 키 설정 열기"
        case .openAccessibilitySettings: return "손쉬운 사용 설정 열기"
        case .retry: return "다시 시도"
        case .typeQuery: return "검색어 입력하기"
        }
    }
}

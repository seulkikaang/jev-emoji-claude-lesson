import SwiftUI

/// The app uses three colors only: white, black, and pink.
enum Theme {
    /// #D81B74. Deep enough that white text on it passes WCAG AA (about 4.8:1).
    static let pink = Color(red: 216 / 255, green: 27 / 255, blue: 116 / 255)
    /// Very light pink for hover and problem backgrounds.
    static let pinkWash = Color(red: 1.0, green: 236 / 255, blue: 244 / 255)
    static let ink = Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    static let inkMuted = ink.opacity(0.62)
    static let hairline = ink.opacity(0.12)
    static let paper = Color.white

    static let panelCorner: CGFloat = 16
    static let cellCorner: CGFloat = 12
}

/// Capsule button in pink, either filled (main action) or outlined (secondary).
struct PillButton: View {
    enum Style { case filled, outlined }

    let title: String
    let style: Style
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    init(title: String, style: Style = .filled, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(style == .filled ? Theme.paper : Theme.pink)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(style == .filled ? Theme.pink : Theme.paper))
                .overlay(Capsule().stroke(Theme.pink, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .opacity(isEnabled ? 1 : 0.4)
    }
}

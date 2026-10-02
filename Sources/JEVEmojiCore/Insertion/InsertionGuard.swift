import Foundation

/// Why the emoji was NOT typed automatically. The emoji is copied to the clipboard instead.
public enum InsertionBlock: Error, Equatable, Sendable {
    case accessibilityNotGranted
    /// The input field could not be identified when the shortcut was pressed.
    case noOriginalField
    case appClosed
    /// Another app is in front now.
    case appChanged
    /// The same app is in front, but the cursor moved to a different field.
    case fieldChanged
    /// The focused field is a password field.
    case secureField
    /// The sentence around the cursor could not be read, so the field is not trusted.
    case contextNotRead
    /// macOS could not tell whether the field accepts text.
    case editabilityUnknown
    /// The field does not accept text.
    case notEditable
    /// The cursor or the selected text is not where it was when the shortcut was pressed.
    case selectionChanged
    case keystrokeFailed

    /// Reason and next step shown in the panel after copying.
    public func clipboardNotice(emoji: String) -> String {
        reason + " " + InsertionResult.pasteHint(emoji: emoji)
    }

    private var reason: String {
        switch self {
        case .accessibilityNotGranted: return "손쉬운 사용 권한이 없어 자동으로 넣지 못했어요."
        case .noOriginalField: return "처음에 입력칸을 확인하지 못해서 자동으로 넣지 않았어요."
        case .appClosed: return "원래 앱이 닫혀서 자동으로 넣지 않았어요."
        case .appChanged: return "그 사이 다른 앱으로 바뀌어서 자동으로 넣지 않았어요."
        case .fieldChanged: return "그 사이 입력칸이 바뀌어서 자동으로 넣지 않았어요."
        case .secureField: return "비밀번호 칸에는 자동으로 넣지 않아요."
        case .contextNotRead: return "처음에 커서 주변 문장을 읽지 못한 입력칸이라 자동으로 넣지 않았어요."
        case .editabilityUnknown: return "이 입력칸에 글을 쓸 수 있는지 확인하지 못해서 자동으로 넣지 않았어요."
        case .notEditable: return "이 칸은 글을 쓸 수 없는 곳이라 자동으로 넣지 않았어요."
        case .selectionChanged: return "그 사이 커서 위치나 선택한 글이 바뀌어서 자동으로 넣지 않았어요."
        case .keystrokeFailed: return "입력을 보내지 못했어요."
        }
    }
}

/// What happened after the user picked an emoji.
public enum InsertionResult: Equatable, Sendable {
    /// Typed, and the emoji was read back from the field at the cursor.
    case inserted
    /// Not typed. The emoji is copied instead.
    case blocked(InsertionBlock)
    /// The keystroke was sent, but the emoji could not be read back from the field.
    /// Sending a key event alone is never reported as success.
    case unconfirmed

    /// Message for the panel, or nil when nothing needs to be shown.
    public func notice(emoji: String) -> String? {
        switch self {
        case .inserted:
            return nil
        case .blocked(let block):
            return block.clipboardNotice(emoji: emoji)
        case .unconfirmed:
            return "이모지 입력을 보냈지만 실제로 들어갔는지 확인하지 못했어요. 원래 입력칸을 확인하고, 없으면 "
                + "\(emoji) 이모지를 클립보드에 복사해 두었으니 ⌘V를 누르세요."
        }
    }

    static func pasteHint(emoji: String) -> String {
        "\(emoji) 이모지를 클립보드에 복사했으니, 넣을 입력칸을 클릭하고 ⌘V를 누르세요."
    }
}

/// Facts gathered right before typing. The app fills this from macOS Accessibility.
public struct FocusCheck: Equatable, Sendable {
    public let originalPID: Int32?
    public let originalFieldKnown: Bool
    public let originalAppRunning: Bool
    /// The sentence around the cursor was read successfully when the shortcut was pressed.
    public let contextWasRead: Bool
    public let currentPID: Int32?
    public let isSameField: Bool
    public let currentFieldIsSecure: Bool
    /// true: accepts text, false: does not, nil: macOS could not tell.
    public let currentFieldIsEditable: Bool?
    /// The cursor position and selection length match the ones captured at the start.
    public let isSameSelection: Bool

    public init(
        originalPID: Int32?,
        originalFieldKnown: Bool,
        originalAppRunning: Bool,
        contextWasRead: Bool,
        currentPID: Int32?,
        isSameField: Bool,
        currentFieldIsSecure: Bool,
        currentFieldIsEditable: Bool?,
        isSameSelection: Bool
    ) {
        self.originalPID = originalPID
        self.originalFieldKnown = originalFieldKnown
        self.originalAppRunning = originalAppRunning
        self.contextWasRead = contextWasRead
        self.currentPID = currentPID
        self.isSameField = isSameField
        self.currentFieldIsSecure = currentFieldIsSecure
        self.currentFieldIsEditable = currentFieldIsEditable
        self.isSameSelection = isSameSelection
    }
}

/// Decides whether typing the emoji is safe. Returns nil only when every check passes.
public enum InsertionGuard {
    public static func block(isAccessibilityGranted: Bool, check: FocusCheck) -> InsertionBlock? {
        guard isAccessibilityGranted else { return .accessibilityNotGranted }
        guard let originalPID = check.originalPID, check.originalFieldKnown else { return .noOriginalField }
        guard check.originalAppRunning else { return .appClosed }
        guard check.currentPID == originalPID else { return .appChanged }
        guard check.isSameField else { return .fieldChanged }
        guard !check.currentFieldIsSecure else { return .secureField }
        guard check.contextWasRead else { return .contextNotRead }
        guard let isEditable = check.currentFieldIsEditable else { return .editabilityUnknown }
        guard isEditable else { return .notEditable }
        guard check.isSameSelection else { return .selectionChanged }
        return nil
    }
}

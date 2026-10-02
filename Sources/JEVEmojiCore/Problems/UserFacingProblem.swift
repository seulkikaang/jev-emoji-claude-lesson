import Foundation

/// A button the user can press to fix a problem.
public enum ProblemAction: String, Equatable, Hashable, Sendable {
    case openAppSettings
    case openAccessibilitySettings
    case retry
    case typeQuery
}

/// What went wrong, why, and what to do next. Shown in the panel instead of a raw error.
public struct UserFacingProblem: Equatable, Sendable {
    public let title: String
    public let reason: String
    public let nextStep: String
    /// The first action is the recommended one.
    public let actions: [ProblemAction]

    public init(title: String, reason: String, nextStep: String, actions: [ProblemAction]) {
        self.title = title
        self.reason = reason
        self.nextStep = nextStep
        self.actions = actions
    }
}

extension UserFacingProblem {
    public init(_ failure: ContextReadFailure) {
        switch failure {
        case .accessibilityNotGranted:
            self.init(
                title: "문장을 읽을 권한이 없어요",
                reason: "macOS 손쉬운 사용 권한이 꺼져 있어서 다른 앱의 커서 주변 글을 읽을 수 없어요.",
                nextStep: "시스템 설정 > 개인정보 보호 및 보안 > 손쉬운 사용에서 JEV Emoji를 켠 뒤 ⌥⌘E를 다시 누르세요. 지금은 검색어로 추천받을 수 있어요.",
                actions: [.openAccessibilitySettings, .typeQuery]
            )
        case .noFrontmostApp:
            self.init(
                title: "글을 쓰던 앱을 찾지 못했어요",
                reason: "단축키를 누를 때 앞에 있던 다른 앱이 없었어요.",
                nextStep: "글을 쓰던 앱의 입력칸을 클릭한 뒤 ⌥⌘E를 누르거나, 검색어를 입력하세요.",
                actions: [.typeQuery]
            )
        case .noFocusedElement(let appName):
            self.init(
                title: "입력 중인 칸을 찾지 못했어요",
                reason: "\(appName)에서 커서가 깜빡이는 입력칸을 찾지 못했어요.",
                nextStep: "입력칸을 한 번 클릭해 커서를 둔 뒤 ⌥⌘E를 다시 누르거나, 검색어를 입력하세요.",
                actions: [.typeQuery]
            )
        case .secureField:
            self.init(
                title: "비밀번호 칸은 읽지 않아요",
                reason: "보안 입력칸이라서 내용을 읽지 않았어요.",
                nextStep: "검색어를 직접 입력해 추천받으세요.",
                actions: [.typeQuery]
            )
        case .notEditableText(let appName):
            self.init(
                title: "이 앱의 글은 읽을 수 없어요",
                reason: "\(appName)이(가) 커서 주변 글을 macOS에 알려 주지 않아요. 일부 웹 브라우저나 Electron 앱에서 생길 수 있어요.",
                nextStep: "검색어를 직접 입력하세요. 고른 이모지는 원래 입력칸에 그대로 들어가요.",
                actions: [.typeQuery]
            )
        case .emptyText:
            self.init(
                title: "읽을 문장이 없어요",
                reason: "커서가 있는 입력칸이 비어 있어요.",
                nextStep: "문장을 먼저 쓰고 ⌥⌘E를 누르거나, 검색어를 입력하세요.",
                actions: [.typeQuery]
            )
        case .timedOut(let appName):
            self.init(
                title: "\(appName)이(가) 응답하지 않아요",
                reason: "앱이 바빠서 커서 주변 글을 제때 알려 주지 못했어요.",
                nextStep: "잠시 뒤 ⌥⌘E를 다시 누르거나, 검색어를 입력하세요.",
                actions: [.typeQuery]
            )
        }
    }

    public init(error: Error) {
        switch error {
        case let failure as ContextReadFailure:
            self.init(failure)
        case let typeSafe as TypeSafeError:
            self.init(typeSafe)
        case is RecommendationInputError:
            self.init(
                title: "추천할 글이 없어요",
                reason: "검색어와 읽은 문장이 모두 비어 있어요.",
                nextStep: "검색어를 입력하고 Return을 누르세요.",
                actions: [.typeQuery]
            )
        case is KeychainError:
            self.init(
                title: "키체인에서 API 키를 읽지 못했어요",
                reason: "맥 키체인이 잠겨 있거나 접근이 거부되었어요.",
                nextStep: "설정에서 API 키를 다시 저장하세요.",
                actions: [.openAppSettings]
            )
        default:
            self.init(
                title: "추천을 가져오지 못했어요",
                reason: "알 수 없는 문제가 생겼어요.",
                nextStep: "다시 시도하세요. 계속되면 앱을 다시 실행하세요.",
                actions: [.retry]
            )
        }
    }

    init(_ error: TypeSafeError) {
        switch error {
        case .missingAPIKey:
            self.init(
                title: "API 키가 필요해요",
                reason: "TypeSafe API 키가 아직 저장되지 않아서 JEV에 물어볼 수 없어요.",
                nextStep: "설정을 열고 TypeSafe 콘솔에서 받은 키를 붙여 넣은 뒤 저장하세요.",
                actions: [.openAppSettings]
            )
        case .unauthorized:
            self.init(
                title: "API 키를 확인해 주세요",
                reason: "TypeSafe가 저장된 키를 받아들이지 않았어요.",
                nextStep: "설정에서 키를 지우고 콘솔에서 새로 받은 키를 저장하세요.",
                actions: [.openAppSettings]
            )
        case .invalidRequest(let status):
            self.init(
                title: "요청 형식이 맞지 않아요",
                reason: "TypeSafe가 요청을 처리하지 못했어요 (오류 코드 \(status)).",
                nextStep: "다른 검색어로 다시 시도하세요. 계속되면 앱을 업데이트하세요.",
                actions: [.retry, .typeQuery]
            )
        case .rateLimited:
            self.init(
                title: "요청이 너무 많아요",
                reason: "짧은 시간에 요청이 몰려 TypeSafe가 잠시 막았어요.",
                nextStep: "몇 초 뒤 다시 시도하세요.",
                actions: [.retry]
            )
        case .overloaded:
            self.init(
                title: "TypeSafe가 바빠요",
                reason: "TypeSafe 서버에 요청이 많아 잠시 처리하지 못했어요.",
                nextStep: "잠시 뒤 다시 시도하세요.",
                actions: [.retry]
            )
        case .server(let status):
            self.init(
                title: "TypeSafe 서버 오류",
                reason: "서버가 오류 코드 \(status)를 돌려줬어요.",
                nextStep: "잠시 뒤 다시 시도하세요.",
                actions: [.retry]
            )
        case .offline:
            self.init(
                title: "인터넷에 연결되어 있지 않아요",
                reason: "JEV 추천은 인터넷으로 TypeSafe에 물어봐야 해요.",
                nextStep: "Wi-Fi나 네트워크를 확인한 뒤 다시 시도하세요.",
                actions: [.retry]
            )
        case .timeout:
            self.init(
                title: "응답이 너무 늦어요",
                reason: "TypeSafe가 정해진 시간 안에 답하지 않았어요.",
                nextStep: "다시 시도하세요.",
                actions: [.retry]
            )
        case .network:
            self.init(
                title: "네트워크 문제가 생겼어요",
                reason: "TypeSafe에 연결하는 중 문제가 생겼어요.",
                nextStep: "네트워크를 확인한 뒤 다시 시도하세요.",
                actions: [.retry]
            )
        case .invalidResponse:
            self.init(
                title: "응답을 이해하지 못했어요",
                reason: "TypeSafe 응답이 예상한 형식과 달라요.",
                nextStep: "다시 시도하세요. 계속되면 앱을 업데이트하세요.",
                actions: [.retry]
            )
        }
    }
}

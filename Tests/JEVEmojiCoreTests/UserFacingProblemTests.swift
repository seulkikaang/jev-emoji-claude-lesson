import Testing
@testable import JEVEmojiCore

struct UserFacingProblemTests {
    private static let contextFailures: [ContextReadFailure] = [
        .accessibilityNotGranted, .noFrontmostApp, .noFocusedElement(appName: "메모"),
        .secureField, .notEditableText(appName: "메모"), .emptyText, .timedOut(appName: "메모")
    ]

    private static let apiErrors: [TypeSafeError] = [
        .missingAPIKey, .unauthorized, .invalidRequest(status: 422), .rateLimited,
        .overloaded, .server(status: 500), .offline, .timeout, .network, .invalidResponse
    ]

    @Test(arguments: contextFailures)
    func contextFailuresExplainReasonAndNextStep(failure: ContextReadFailure) {
        let problem = UserFacingProblem(failure)
        #expect(!problem.title.isEmpty)
        #expect(!problem.reason.isEmpty)
        #expect(!problem.nextStep.isEmpty)
        // Every reading failure still lets the user search by keyword.
        #expect(problem.actions.contains(.typeQuery))
    }

    @Test(arguments: apiErrors)
    func apiErrorsExplainReasonAndNextStep(error: TypeSafeError) {
        let problem = UserFacingProblem(error: error)
        #expect(!problem.reason.isEmpty)
        #expect(!problem.nextStep.isEmpty)
        #expect(!problem.actions.isEmpty)
    }

    @Test func missingPermissionPointsToAccessibilitySettingsFirst() {
        #expect(UserFacingProblem(ContextReadFailure.accessibilityNotGranted).actions.first == .openAccessibilitySettings)
    }

    @Test func keyProblemsPointToAppSettings() {
        #expect(UserFacingProblem(error: TypeSafeError.missingAPIKey).actions == [.openAppSettings])
        #expect(UserFacingProblem(error: TypeSafeError.unauthorized).actions == [.openAppSettings])
    }
}

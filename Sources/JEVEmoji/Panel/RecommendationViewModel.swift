import Foundation
import JEVEmojiCore

/// State of the small recommendation window: what was read, loading, results, or a problem.
@MainActor
final class RecommendationViewModel: ObservableObject {
    enum Phase: Equatable {
        case idle
        case loading
        case results([EmojiRecommendation])
        case problem(UserFacingProblem)
    }

    struct SourceDescription: Equatable {
        let label: String
        let text: String
    }

    @Published var query = ""
    @Published private(set) var phase: Phase = .idle
    @Published private(set) var sourceDescription: SourceDescription?
    @Published var notice: String?
    /// Incremented to ask the view to focus the search field.
    @Published private(set) var focusSearchRequest = 0

    var onClose: (() -> Void)?
    var onPick: ((String) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onOpenAccessibilitySettings: (() -> Void)?

    private let recommender: any EmojiRecommending
    private var task: Task<Void, Never>?
    private var capturedText: String?
    private var lastRequest: (text: String, source: TextSource)?

    init(recommender: any EmojiRecommending) {
        self.recommender = recommender
    }

    func begin(with result: Result<String, ContextReadFailure>) {
        reset()
        switch result {
        case .success(let text):
            capturedText = text
            recommend(text: text, source: .cursorContext)
        case .failure(let failure):
            phase = .problem(UserFacingProblem(failure))
            requestSearchFocus()
        }
    }

    /// Return in the search field. An empty query re-runs the sentence that was read.
    func submitQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            recommend(text: trimmed, source: .searchQuery)
        } else if let capturedText {
            recommend(text: capturedText, source: .cursorContext)
        } else {
            phase = .problem(UserFacingProblem(error: RecommendationInputError.emptyText))
            requestSearchFocus()
        }
    }

    func pick(_ item: EmojiRecommendation) {
        onPick?(item.emoji)
    }

    func close() {
        onClose?()
    }

    func openSettings() {
        onOpenSettings?()
    }

    func perform(_ action: ProblemAction) {
        switch action {
        case .openAppSettings:
            onOpenSettings?()
        case .openAccessibilitySettings:
            onOpenAccessibilitySettings?()
        case .retry:
            if let lastRequest {
                recommend(text: lastRequest.text, source: lastRequest.source)
            }
        case .typeQuery:
            requestSearchFocus()
        }
    }

    func reset() {
        task?.cancel()
        task = nil
        query = ""
        phase = .idle
        sourceDescription = nil
        notice = nil
        capturedText = nil
        lastRequest = nil
    }

    private func recommend(text: String, source: TextSource) {
        task?.cancel()
        notice = nil
        lastRequest = (text, source)
        sourceDescription = SourceDescription(
            label: source == .cursorContext ? "읽은 문장" : "검색어",
            text: ContextExtractor.normalized(text)
        )
        phase = .loading

        let recommender = self.recommender
        task = Task { [weak self] in
            do {
                let result = try await recommender.recommend(for: text, source: source)
                guard !Task.isCancelled else { return }
                self?.phase = .results(result.items)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else { return }
                self?.phase = .problem(UserFacingProblem(error: error))
            }
        }
    }

    private func requestSearchFocus() {
        focusSearchRequest += 1
    }
}

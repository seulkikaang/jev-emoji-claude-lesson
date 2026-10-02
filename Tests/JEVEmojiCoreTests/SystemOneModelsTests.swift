import Foundation
import Testing
@testable import JEVEmojiCore

struct SystemOneModelsTests {
    @Test func encodesChoiceQuestionLikeTheDocs() throws {
        let request = SystemOneRequest(
            state: TextState(text: "축하해", kind: "search_query"),
            model: "jev-latest",
            questions: ["emoji": ChoiceQuestion(instructions: "Pick one", criteria: ["tada": "🎉"])]
        )
        let data = try JSONEncoder().encode(request)
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["model"] as? String == "jev-latest")
        let state = try #require(json["state"] as? [String: Any])
        #expect(state["text"] as? String == "축하해")
        let questions = try #require(json["questions"] as? [String: Any])
        let emoji = try #require(questions["emoji"] as? [String: Any])
        #expect(emoji["type"] as? String == "choice")
        #expect((emoji["criteria"] as? [String: String])?["tada"] == "🎉")
    }

    @Test func decodesDocumentedChoiceResponse() throws {
        let body = """
        {
          "model": "jev-1.13.0",
          "answers": {
            "department": {
              "type": "choice",
              "choice": "billing",
              "probabilities": { "billing": 0.88, "technical": 0.12, "sales": 0.0 },
              "confidence": 0.81
            }
          },
          "usage": { "input_tokens": 318, "output_tokens": 34 }
        }
        """
        let response = try JSONDecoder().decode(SystemOneResponse.self, from: Data(body.utf8))
        #expect(response.model == "jev-1.13.0")
        #expect(response.answers["department"]?.choice == "billing")
        #expect(response.answers["department"]?.probabilities?["billing"] == 0.88)
        #expect(response.usage?.inputTokens == 318)
    }
}

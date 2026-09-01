import Foundation

struct InsightsResponse:
    Codable,
    Equatable {

    let notesCount: Int
    let topicsCount: Int
    let actionsCount: Int
    let decisionsCount: Int

    let themes: [String]
    let decisions: [String]
    let actionItems: [String]

    let aiInsight: String

    let generatedAt: String?

    enum CodingKeys:
        String,
        CodingKey {

        case notesCount =
            "notes_count"

        case topicsCount =
            "topics_count"

        case actionsCount =
            "actions_count"

        case decisionsCount =
            "decisions_count"

        case themes
        case decisions

        case actionItems =
            "action_items"

        case aiInsight =
            "ai_insight"

        case generatedAt =
            "generated_at"
    }
}

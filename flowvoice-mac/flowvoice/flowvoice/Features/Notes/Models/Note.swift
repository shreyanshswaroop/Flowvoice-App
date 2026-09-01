import Foundation

struct Note: Identifiable, Codable, Equatable {

    let id: String
    let title: String
    let transcript: String
    let durationSeconds: Int?

    let segments: [NoteSpeakerSegment]

    let summary: String?
    let keyPoints: [String]
    let actionItems: [String]

    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case transcript

        case durationSeconds =
            "duration_seconds"

        case segments

        case summary

        case keyPoints =
            "key_points"

        case actionItems =
            "action_items"

        case createdAt =
            "created_at"

        case updatedAt =
            "updated_at"
    }
}

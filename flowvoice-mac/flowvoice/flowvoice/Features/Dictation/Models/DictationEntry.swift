import Foundation

struct DictationEntry: Identifiable, Equatable {

    let id: String
    let remoteID: String?
    let time: String
    let text: String
    let createdAt: Date?

    init(
        id: String = UUID().uuidString,
        remoteID: String? = nil,
        time: String,
        text: String,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.time = time
        self.text = text
        self.createdAt = createdAt
    }

    static func parseDate(_ value: String) -> Date? {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: value) { return date }
        parser.formatOptions = [.withInternetDateTime]
        return parser.date(from: value)
    }
}

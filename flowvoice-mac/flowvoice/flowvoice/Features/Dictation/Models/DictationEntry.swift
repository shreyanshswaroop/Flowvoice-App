import Foundation

struct DictationEntry: Identifiable, Equatable {

    let id: String
    let remoteID: String?
    let time: String
    let text: String

    init(
        id: String = UUID().uuidString,
        remoteID: String? = nil,
        time: String,
        text: String
    ) {
        self.id = id
        self.remoteID = remoteID
        self.time = time
        self.text = text
    }
}

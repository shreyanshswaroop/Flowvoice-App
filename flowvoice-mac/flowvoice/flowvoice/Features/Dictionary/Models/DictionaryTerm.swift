import Foundation

enum DictionaryEntryType:
    String,
    Codable,
    CaseIterable {

    case term
    case replacement

    var displayName: String {

        switch self {

        case .term:
            return "Word or phrase"

        case .replacement:
            return "Replacement"
        }
    }
}


enum DictionaryScope:
    String,
    Codable,
    CaseIterable {

    case personal
    case shared

    var displayName: String {

        switch self {

        case .personal:
            return "Personal"

        case .shared:
            return "Shared"
        }
    }
}


enum DictionarySource:
    String,
    Codable {

    case manual
    case suggested
}


struct DictionaryEntry:
    Identifiable,
    Codable,
    Equatable {

    let id: String

    let type:
        DictionaryEntryType

    let value: String

    let replacement:
        String?

    let scope:
        DictionaryScope

    let source:
        DictionarySource

    let active: Bool

    let createdAt: String
    let updatedAt: String

    enum CodingKeys:
        String,
        CodingKey {

        case id
        case type
        case value
        case replacement
        case scope
        case source
        case active

        case createdAt =
            "created_at"

        case updatedAt =
            "updated_at"
    }

    var displayText: String {

        if
            type == .replacement,
            let replacement,
            !replacement.isEmpty {

            return "\(value) → \(replacement)"
        }

        return value
    }

    var isSuggestion: Bool {

        source == .suggested
    }

    var canSendToDeepgram: Bool {

        type == .term
        &&
        active
        &&
        source == .manual
    }
}

enum SidebarTab:
    String,
    CaseIterable,
    Identifiable {

    case dictation = "Dictation"
    case notetaker = "Notetaker"
    case insights = "Insights"
    case dictionary = "Dictionary"
    case snippets = "Snippets"
    case style = "Style"
    case transforms = "Transforms"
    case scratchpad = "Scratchpad"

    case settings = "Settings"
    case help = "Help"

    var id: String {
        rawValue
    }


    var icon: String {

        switch self {

        case .dictation:
            return "mic"

        case .notetaker:
            return "note.text"

        case .insights:
            return "sparkles"

        case .dictionary:
            return "text.book.closed"

        case .snippets:
            return "text.quote"

        case .style:
            return "textformat"

        case .transforms:
            return "wand.and.stars"

        case .scratchpad:
            return "square.and.pencil"

        case .settings:
            return "gearshape"

        case .help:
            return "questionmark.circle"
        }
    }

    static var primaryTabs: [SidebarTab] {

        [
            .dictation,
            .notetaker,
            .insights,
            .dictionary,
            .snippets,
            .style,
            .transforms,
            .scratchpad
        ]
    }

    static var secondaryTabs: [SidebarTab] {

        [
            .settings,
            .help
        ]
    }
}

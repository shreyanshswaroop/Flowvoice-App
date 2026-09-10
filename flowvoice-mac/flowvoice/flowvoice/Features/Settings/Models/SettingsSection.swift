enum SettingsSection:
    String,
    CaseIterable,
    Identifiable {

    // Main settings
    case general
    case profile
    case calendar
    case notifications
    case connectors
    case getHelp

    // Workspace
    case workspaceGeneral
    case members
    case spaces
    case billing
    case referrals

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .general:
            return "Preferences"

        case .profile:
            return "Profile"

        case .calendar:
            return "Calendar"

        case .notifications:
            return "Notifications"

        case .connectors:
            return "Connectors"

        case .getHelp:
            return "Get help"

        case .workspaceGeneral:
            return "General"

        case .members:
            return "Members"

        case .spaces:
            return "Spaces"

        case .billing:
            return "Billing"

        case .referrals:
            return "Referrals"
        }
    }

    var icon: String {

        switch self {

        case .general:
            return "slider.horizontal.3"

        case .profile:
            return "person"

        case .calendar:
            return "calendar"

        case .notifications:
            return "bell"

        case .connectors:
            return "circle.grid.2x2"

        case .getHelp:
            return "questionmark.circle"

        case .workspaceGeneral:
            return "building.2"

        case .members:
            return "person.2"

        case .spaces:
            return "folder"

        case .billing:
            return "creditcard"

        case .referrals:
            return "gift"
        }
    }

    static var personalSections: [SettingsSection] {
        [
            .general,
            .profile,
            .calendar,
            .notifications,
            .connectors,
            .getHelp
        ]
    }

    static var workspaceSections: [SettingsSection] {
        [
            .workspaceGeneral,
            .members,
            .spaces,
            .billing,
            .referrals
        ]
    }
}

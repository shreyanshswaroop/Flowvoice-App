import Foundation

enum SettingsSection:
    String,
    CaseIterable,
    Identifiable {

    case general
    case voice
    case account
    case keyboard
    case storage
    case privacy

    var id: String {
        rawValue
    }

    var title: String {

        switch self {

        case .general:
            return "General"

        case .voice:
            return "Voice"

        case .account:
            return "Account"

        case .keyboard:
            return "Keyboard"

        case .storage:
            return "Storage"

        case .privacy:
            return "Privacy"
        }
    }

    var icon: String {

        switch self {

        case .general:
            return "gearshape"

        case .voice:
            return "waveform"

        case .account:
            return "person.crop.circle"

        case .keyboard:
            return "keyboard"

        case .storage:
            return "internaldrive"

        case .privacy:
            return "lock.shield"
        }
    }
}

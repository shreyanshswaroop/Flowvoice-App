import AppKit

extension Notification.Name {

    static let toggleFlowVoiceSidebar =
        Notification.Name(
            "toggleFlowVoiceSidebar"
        )

    static let flowVoiceSidebarStateChanged =
        Notification.Name(
            "flowVoiceSidebarStateChanged"
        )
    
    static let flowVoiceSettingsStateChanged =
        Notification.Name(
            "flowVoiceSettingsStateChanged"
        )

    static let flowVoiceAppearanceChanged =
        Notification.Name(
            "flowVoiceAppearanceChanged"
        )
}

final class SidebarTitlebarButtonHandler: NSObject {

    @objc
    func toggleSidebar() {

        NotificationCenter.default.post(
            name: .toggleFlowVoiceSidebar,
            object: nil
        )
    }
}

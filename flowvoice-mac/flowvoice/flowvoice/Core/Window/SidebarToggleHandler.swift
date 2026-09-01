import Foundation
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

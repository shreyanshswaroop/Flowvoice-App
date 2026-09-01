import SwiftUI

struct StorageSettingsView: View {

    @State private var saveHistory = true
    @State private var retention = "Forever"

    var body: some View {

        settingsPage(
            title: "Storage"
        ) {

            SettingsToggleRow(
                title: "Save dictation history",
                subtitle:
                    "Keep completed dictations available inside FlowVoice.",
                isOn: $saveHistory
            )

            SettingsSelectRow(
                title: "History retention",
                value: retention
            )

            SettingsActionRow(
                title: "Clear dictation history",
                tint: .red
            )
        }
    }
}

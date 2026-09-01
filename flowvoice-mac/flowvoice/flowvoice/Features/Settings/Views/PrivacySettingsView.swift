import SwiftUI

struct PrivacySettingsView: View {

    @State private var analytics = false
    @State private var improveRecognition = false

    var body: some View {

        settingsPage(
            title: "Privacy"
        ) {

            SettingsToggleRow(
                title: "Share anonymous analytics",
                subtitle:
                    "Help improve FlowVoice by sharing anonymous usage information.",
                isOn: $analytics
            )

            SettingsToggleRow(
                title: "Improve voice recognition",
                subtitle:
                    "Allow anonymized voice-processing diagnostics.",
                isOn: $improveRecognition
            )
        }
    }
}

import SwiftUI

struct VoiceSettingsView: View {

    @State private var microphone = "System Default"
    @State private var language = "Auto-detect"
    @State private var livePreview = true
    @State private var autoPunctuation = true
    @State private var soundFeedback = false

    var body: some View {

        settingsPage(
            title: "Voice"
        ) {

            SettingsSelectRow(
                title: "Microphone",
                value: microphone
            )

            SettingsSelectRow(
                title: "Recognition language",
                value: language
            )

            SettingsToggleRow(
                title: "Live transcript preview",
                subtitle:
                    "Show words while you are speaking.",
                isOn: $livePreview
            )

            SettingsToggleRow(
                title: "Automatic punctuation",
                subtitle:
                    "Add punctuation automatically to completed dictations.",
                isOn: $autoPunctuation
            )

            SettingsToggleRow(
                title: "Sound feedback",
                subtitle:
                    "Play subtle sounds when dictation begins and ends.",
                isOn: $soundFeedback
            )
        }
    }
}

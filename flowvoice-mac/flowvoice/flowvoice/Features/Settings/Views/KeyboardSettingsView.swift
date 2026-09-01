import SwiftUI

struct KeyboardSettingsView: View {

    @State private var shortcut = "⌥ Space"
    @State private var holdToSpeak = true

    var body: some View {

        settingsPage(
            title: "Keyboard"
        ) {

            SettingsSelectRow(
                title: "Global shortcut",
                value: shortcut
            )

            SettingsToggleRow(
                title: "Hold to speak",
                subtitle:
                    "Keep the shortcut pressed while speaking and release to transcribe.",
                isOn: $holdToSpeak
            )
        }
    }
}

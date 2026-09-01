import SwiftUI

struct GeneralSettingsView: View {

    @State private var appearance = "System"
    @State private var language = "Auto-detect"
    @State private var launchAtLogin = true
    @State private var showMenuBarIcon = true

    var body: some View {

        settingsPage(
            title: "General"
        ) {

            SettingsSelectRow(
                title: "Appearance",
                value: appearance
            )

            SettingsSelectRow(
                title: "Language",
                value: language
            )

            SettingsToggleRow(
                title: "Launch at login",
                subtitle:
                    "Start FlowVoice automatically when you sign in to your Mac.",
                isOn: $launchAtLogin
            )

            SettingsToggleRow(
                title: "Show in menu bar",
                subtitle:
                    "Keep quick FlowVoice controls available in the menu bar.",
                isOn: $showMenuBarIcon
            )
        }
    }
}

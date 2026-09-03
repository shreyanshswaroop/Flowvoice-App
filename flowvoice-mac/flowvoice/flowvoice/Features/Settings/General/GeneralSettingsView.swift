import SwiftUI

struct GeneralSettingsView: View {

    // MARK: - General

    @State private var liveMeetingIndicator = true
    @State private var launchAtLogin = true
    @State private var repositionForMeetings = true
    @State private var pauseMusicForMeetings = false
    @State private var showMenuBarIcon = true

    // MARK: - Features

    @State private var speakerTags = true
    @State private var suggestedFollowUpEmails = false

    // MARK: - Appearance

    @AppStorage(FlowVoiceAppearance.storageKey)
    private var appearance =
        FlowVoiceAppearance.system.rawValue
    @State private var selectedAppIcon = 0

    // MARK: - Data & Sharing

    @State private var defaultLinkSharing = "Anyone with the link"
    @State private var improveModels = false
    @State private var transcriptRetention = "Off"

    // MARK: - Language

    @State private var transcriptionLanguage = "English"
    @State private var summaryLanguage = "English"
    @State private var internalJargon = ""

    // MARK: - Transparency

    @State private var automatedChatMessage = false
    @State private var flowVoiceWatermark = false

    var body: some View {

        ScrollView {

            HStack {
                Spacer()

                VStack(
                    alignment: .leading,
                    spacing: 30
                ) {

                    header

                    generalSection

                    featuresSection

                    appearanceSection

                    dataSharingSection

                    languageSection

                    transparencySection
                }
                .frame(
                    maxWidth: 620,
                    alignment: .leading
                )
                .padding(.horizontal, 28)
                .padding(.top, 26)
                .padding(.bottom, 60)

                Spacer()
            }
            .frame(
                maxWidth: .infinity,
                alignment: .top
            )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Header

    private var header: some View {

        Text("Preferences")
            .font(
                .system(
                    size: 30,
                    weight: .regular,
                    design: .serif
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
    }

    // MARK: - General

    private var generalSection: some View {

        SettingsPreferenceSection(
            title: "General"
        ) {

            PreferenceToggleRow(
                icon: "waveform",
                title: "Live meeting indicator",
                subtitle:
                    "Shows when FlowVoice is actively transcribing.",
                isOn: $liveMeetingIndicator
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "power",
                title: "Open FlowVoice when you log in",
                subtitle:
                    "FlowVoice will open automatically when you sign in.",
                isOn: $launchAtLogin
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "rectangle.on.rectangle",
                title: "Reposition FlowVoice for meetings",
                subtitle:
                    "FlowVoice moves aside during meetings and restores its position afterwards.",
                isOn: $repositionForMeetings
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "pause.fill",
                title: "Pause music when joining a meeting",
                subtitle:
                    "Automatically pause currently playing media when a meeting starts.",
                isOn: $pauseMusicForMeetings
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "menubar.rectangle",
                title: "Show in menu bar",
                subtitle:
                    "Keep quick FlowVoice controls available in the menu bar.",
                isOn: $showMenuBarIcon
            )
        }
    }

    // MARK: - Features

    private var featuresSection: some View {

        SettingsPreferenceSection(
            title: "Features"
        ) {

            PreferenceToggleRow(
                icon: "person.wave.2",
                title: "Speaker tags",
                subtitle:
                    "Identify who is speaking in your meetings and notes.",
                isOn: $speakerTags
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "envelope.badge",
                title: "Suggested follow-up emails",
                subtitle:
                    "Create suggested follow-up emails after your meeting ends.",
                isOn: $suggestedFollowUpEmails
            )
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {

        SettingsPreferenceSection(
            title: "Appearance"
        ) {

            PreferencePickerRow(
                icon: "circle.lefthalf.filled",
                title: "Theme",
                subtitle:
                    "Choose your FlowVoice interface appearance.",
                selection: $appearance,
                options:
                    FlowVoiceAppearance.allCases.map(\.rawValue)
            )

            preferenceDivider

            VStack(
                alignment: .leading,
                spacing: 12
            ) {

                PreferenceRowHeader(
                    icon: "paintbrush",
                    title: "App icon",
                    subtitle:
                        "Choose how FlowVoice appears on your Mac."
                )

                HStack(spacing: 10) {

                    ForEach(0..<6, id: \.self) { index in

                        appIconButton(
                            index: index
                        )
                    }
                }
                .padding(.leading, 42)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Data & Sharing

    private var dataSharingSection: some View {

        SettingsPreferenceSection(
            title: "Data & sharing"
        ) {

            PreferencePickerRow(
                icon: "link",
                title: "Default link sharing",
                subtitle:
                    "Choose who can access notes you share.",
                selection: $defaultLinkSharing,
                options: [
                    "Anyone with the link",
                    "Only me",
                    "Workspace members"
                ]
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "brain",
                title: "Use my data to improve FlowVoice",
                subtitle:
                    "Allow anonymized usage data to help improve FlowVoice.",
                isOn: $improveModels
            )

            preferenceDivider

            PreferencePickerRow(
                icon: "clock",
                title: "Auto deletion period for transcripts",
                subtitle:
                    "Automatically delete transcripts after a selected period.",
                selection: $transcriptRetention,
                options: [
                    "Off",
                    "7 days",
                    "30 days",
                    "90 days",
                    "1 year"
                ]
            )
        }
    }

    // MARK: - Language

    private var languageSection: some View {

        SettingsPreferenceSection(
            title: "Language"
        ) {

            PreferencePickerRow(
                icon: "character.bubble",
                title: "Transcription language",
                subtitle:
                    "Select the language you normally speak.",
                selection: $transcriptionLanguage,
                options: [
                    "English",
                    "Auto-detect",
                    "Hindi",
                    "Spanish",
                    "French",
                    "German"
                ]
            )

            preferenceDivider

            PreferencePickerRow(
                icon: "text.alignleft",
                title: "Summary language",
                subtitle:
                    "Choose the language used for generated notes.",
                selection: $summaryLanguage,
                options: [
                    "English",
                    "Hindi",
                    "Spanish",
                    "French",
                    "German"
                ]
            )

            preferenceDivider

            VStack(
                alignment: .leading,
                spacing: 10
            ) {

                PreferenceRowHeader(
                    icon: "text.book.closed",
                    title: "Internal jargon",
                    subtitle:
                        "Add names, products, acronyms, or technical terms FlowVoice should recognize."
                )

                TextField(
                    "Moove, Callipo, Project AlphaDuck...",
                    text: $internalJargon
                )
                .textFieldStyle(.plain)
                .font(
                    .system(size: 13)
                )
                .padding(.horizontal, 12)
                .frame(height: 42)
                .background {
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .fill(
                        Color.primary
                            .opacity(0.035)
                    )
                }
                .overlay {
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                    .stroke(
                        Color.primary
                            .opacity(0.10),
                        lineWidth: 1
                    )
                }
                .padding(.leading, 42)
                .padding(.trailing, 14)
                .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Transparency

    private var transparencySection: some View {

        SettingsPreferenceSection(
            title: "Transparency"
        ) {

            PreferenceToggleRow(
                icon: "message",
                title: "Automated chat message",
                subtitle:
                    "Automatically send a message when meeting transcription starts.",
                isOn: $automatedChatMessage
            )

            preferenceDivider

            PreferenceToggleRow(
                icon: "record.circle",
                title: "FlowVoice watermark",
                subtitle:
                    "Show a small FlowVoice indicator while transcription is active.",
                isOn: $flowVoiceWatermark
            )
        }
    }

    // MARK: - App Icons

    private func appIconButton(
        index: Int
    ) -> some View {

        Button {

            withAnimation(
                .easeInOut(duration: 0.15)
            ) {
                selectedAppIcon = index
            }

        } label: {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .fill(
                    selectedAppIcon == index
                        ? Color.primary.opacity(0.14)
                        : Color.primary.opacity(0.05)
                )

                Image(
                    systemName: "waveform"
                )
                .font(
                    .system(
                        size: 18,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    selectedAppIcon == index
                        ? Color.primary
                        : Color.secondary
                )
            }
            .frame(
                width: 42,
                height: 42
            )
            .overlay {

                if selectedAppIcon == index {

                    RoundedRectangle(
                        cornerRadius: 10,
                        style: .continuous
                    )
                    .stroke(
                        Color.primary.opacity(0.25),
                        lineWidth: 1
                    )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Divider

    private var preferenceDivider: some View {

        Rectangle()
            .fill(
                Color.primary
                    .opacity(0.07)
            )
            .frame(height: 1)
            .padding(.leading, 42)
    }
}

// MARK: - Settings Section

private struct SettingsPreferenceSection<
    Content: View
>: View {

    let title: String

    @ViewBuilder
    let content: Content

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text(title)
                .font(
                    .system(
                        size: 12,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.secondary
                )
                .padding(.leading, 8)

            VStack(
                spacing: 0
            ) {
                content
            }
            .background {

                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .fill(
                    Color.primary
                        .opacity(0.025)
                )
            }
            .overlay {

                RoundedRectangle(
                    cornerRadius: 14,
                    style: .continuous
                )
                .stroke(
                    Color.primary
                        .opacity(0.10),
                    lineWidth: 1
                )
            }
        }
    }
}

// MARK: - Header

private struct PreferenceRowHeader: View {

    let icon: String
    let title: String
    let subtitle: String

    var body: some View {

        HStack(
            alignment: .top,
            spacing: 10
        ) {

            PreferenceIcon(
                systemName: icon
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                Text(subtitle)
                    .font(
                        .system(size: 11.5)
                    )
                    .foregroundStyle(
                        Color.secondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(
                minLength: 10
            )
        }
        .padding(
            EdgeInsets(
                top: 12,
                leading: 12,
                bottom: 12,
                trailing: 12
            )
        )
    }
}

// MARK: - Toggle Row

private struct PreferenceToggleRow: View {

    let icon: String
    let title: String
    let subtitle: String

    @Binding var isOn: Bool

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 10
        ) {

            PreferenceIcon(
                systemName: icon
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                Text(subtitle)
                    .font(
                        .system(size: 11.5)
                    )
                    .foregroundStyle(
                        Color.secondary
                    )
            }

            Spacer(
                minLength: 20
            )

            Toggle(
                "",
                isOn: $isOn
            )
            .labelsHidden()
            .toggleStyle(
                .switch
            )
            .controlSize(
                .small
            )
        }
        .padding(
            EdgeInsets(
                top: 11,
                leading: 12,
                bottom: 11,
                trailing: 14
            )
        )
    }
}

// MARK: - Picker Row

private struct PreferencePickerRow: View {

    let icon: String
    let title: String
    let subtitle: String

    @Binding var selection: String

    let options: [String]

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 10
        ) {

            PreferenceIcon(
                systemName: icon
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                Text(subtitle)
                    .font(
                        .system(size: 11.5)
                    )
                    .foregroundStyle(
                        Color.secondary
                    )
            }

            Spacer(
                minLength: 20
            )

            Picker(
                "",
                selection: $selection
            ) {

                ForEach(
                    options,
                    id: \.self
                ) { option in

                    Text(option)
                        .tag(option)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(
                width: 160
            )
        }
        .padding(
            EdgeInsets(
                top: 11,
                leading: 12,
                bottom: 11,
                trailing: 12
            )
        )
    }
}

// MARK: - Preference Icon

private struct PreferenceIcon: View {

    let systemName: String

    var body: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 7,
                style: .continuous
            )
            .fill(
                Color.primary
                    .opacity(0.055)
            )

            Image(
                systemName: systemName
            )
            .font(
                .system(
                    size: 12,
                    weight: .medium
                )
            )
            .foregroundStyle(
                Color.secondary
            )
        }
        .frame(
            width: 30,
            height: 30
        )
    }
}

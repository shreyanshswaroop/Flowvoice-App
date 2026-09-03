import SwiftUI

struct CalendarSettingsView: View {

    @State private var googleConnected = false
    @State private var appleConnected = true

    @State private var defaultCalendar = "Apple Calendar"

    @State private var autoDetectMeetings = true
    @State private var autoStartNotes = true
    @State private var meetingReminder = true
    @State private var ignoreShortMeetings = false
    @State private var ignoreSoloEvents = true

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 30
            ) {

                header

                connectedCalendarsSection

                preferencesSection
            }
            .frame(
                maxWidth: 620,
                alignment: .leading
            )
            .padding(.horizontal, 28)
            .padding(.top, 26)
            .padding(.bottom, 60)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .top
        )
    }

    // MARK: - Header

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Calendar")
                .font(
                    .system(
                        size: 30,
                        weight: .regular,
                        design: .serif
                    )
                )

            Text(
                "Connect your calendars and choose how FlowVoice handles meetings."
            )
            .font(
                .system(size: 13)
            )
            .foregroundStyle(
                Color.secondary
            )
        }
    }

    // MARK: - Connected Calendars

    private var connectedCalendarsSection: some View {

        CalendarSettingsSection(
            title: "Connected calendars"
        ) {

            CalendarConnectionRow(
                icon: "g.circle.fill",
                title: "Google Calendar",
                subtitle:
                    googleConnected
                    ? "Connected"
                    : "Connect your Google Calendar account.",
                isConnected: googleConnected
            ) {

                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    googleConnected.toggle()
                }
            }

            calendarDivider

            CalendarConnectionRow(
                icon: "calendar",
                title: "Apple Calendar",
                subtitle:
                    appleConnected
                    ? "Connected"
                    : "Connect Apple Calendar.",
                isConnected: appleConnected
            ) {

                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    appleConnected.toggle()
                }
            }

            calendarDivider

            CalendarPickerRow(
                icon: "calendar.badge.clock",
                title: "Default calendar",
                subtitle:
                    "Choose which calendar FlowVoice should use by default.",
                selection: $defaultCalendar,
                options: [
                    "Apple Calendar",
                    "Google Calendar"
                ]
            )
        }
    }

    // MARK: - Preferences

    private var preferencesSection: some View {

        CalendarSettingsSection(
            title: "Meeting preferences"
        ) {

            CalendarToggleRow(
                icon: "calendar.badge.plus",
                title: "Automatically detect meetings",
                subtitle:
                    "FlowVoice will detect upcoming meetings from your connected calendars.",
                isOn: $autoDetectMeetings
            )

            calendarDivider

            CalendarToggleRow(
                icon: "waveform",
                title: "Start note-taking automatically",
                subtitle:
                    "Begin capturing notes when a scheduled meeting starts.",
                isOn: $autoStartNotes
            )

            calendarDivider

            CalendarToggleRow(
                icon: "bell",
                title: "Meeting reminder",
                subtitle:
                    "Show a reminder shortly before a scheduled meeting begins.",
                isOn: $meetingReminder
            )

            calendarDivider

            CalendarToggleRow(
                icon: "clock",
                title: "Ignore short meetings",
                subtitle:
                    "Skip automatic note-taking for very short calendar events.",
                isOn: $ignoreShortMeetings
            )

            calendarDivider

            CalendarToggleRow(
                icon: "person",
                title: "Ignore events without attendees",
                subtitle:
                    "Do not automatically start note-taking for personal calendar events.",
                isOn: $ignoreSoloEvents
            )
        }
    }

    // MARK: - Divider

    private var calendarDivider: some View {

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

private struct CalendarSettingsSection<
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

// MARK: - Connection Row

private struct CalendarConnectionRow: View {

    let icon: String
    let title: String
    let subtitle: String
    let isConnected: Bool
    let action: () -> Void

    var body: some View {

        HStack(
            spacing: 10
        ) {

            CalendarIcon(
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

            Spacer()

            Button(
                isConnected
                    ? "Disconnect"
                    : "Connect"
            ) {
                action()
            }
            .buttonStyle(.plain)
            .font(
                .system(
                    size: 12,
                    weight: .medium
                )
            )
            .foregroundStyle(
                isConnected
                    ? Color.secondary
                    : Color.primary
            )
            .padding(
                .horizontal,
                14
            )
            .frame(
                height: 30
            )
            .background {

                Capsule()
                    .fill(
                        Color.primary
                            .opacity(0.045)
                    )
            }
            .overlay {

                Capsule()
                    .stroke(
                        Color.primary
                            .opacity(0.10),
                        lineWidth: 1
                    )
            }
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

// MARK: - Toggle Row

private struct CalendarToggleRow: View {

    let icon: String
    let title: String
    let subtitle: String

    @Binding var isOn: Bool

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 10
        ) {

            CalendarIcon(
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
            .toggleStyle(.switch)
            .controlSize(.small)
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

private struct CalendarPickerRow: View {

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

            CalendarIcon(
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

// MARK: - Icon

private struct CalendarIcon: View {

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

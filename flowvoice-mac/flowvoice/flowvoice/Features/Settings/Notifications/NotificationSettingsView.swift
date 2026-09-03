import SwiftUI

struct NotificationSettingsView: View {

    @State private var dictationComplete = true
    @State private var meetingNoteReady = true
    @State private var meetingReminder = true
    @State private var connectionAlerts = true
    @State private var soundFeedback = true
    @State private var desktopNotifications = true

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 30
            ) {

                header

                notificationSection

                soundSection
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

            Text("Notifications")
                .font(
                    .system(
                        size: 30,
                        weight: .regular,
                        design: .serif
                    )
                )

            Text(
                "Choose when FlowVoice should notify you."
            )
            .font(
                .system(size: 13)
            )
            .foregroundStyle(
                Color.secondary
            )
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {

        NotificationSettingsSection(
            title: "Notifications"
        ) {

            NotificationToggleRow(
                icon: "text.bubble",
                title: "Dictation complete",
                subtitle:
                    "Notify me when a dictation has finished processing.",
                isOn: $dictationComplete
            )

            divider

            NotificationToggleRow(
                icon: "note.text",
                title: "Meeting note ready",
                subtitle:
                    "Notify me when FlowVoice finishes generating meeting notes.",
                isOn: $meetingNoteReady
            )

            divider

            NotificationToggleRow(
                icon: "calendar.badge.clock",
                title: "Meeting reminders",
                subtitle:
                    "Show a reminder before an upcoming calendar meeting.",
                isOn: $meetingReminder
            )

            divider

            NotificationToggleRow(
                icon: "wifi.exclamationmark",
                title: "Connection and error alerts",
                subtitle:
                    "Notify me when FlowVoice loses connection or needs attention.",
                isOn: $connectionAlerts
            )

            divider

            NotificationToggleRow(
                icon: "bell",
                title: "Desktop notifications",
                subtitle:
                    "Allow FlowVoice to show macOS notifications.",
                isOn: $desktopNotifications
            )
        }
    }

    // MARK: - Sound

    private var soundSection: some View {

        NotificationSettingsSection(
            title: "Sound"
        ) {

            NotificationToggleRow(
                icon: "speaker.wave.2",
                title: "Sound feedback",
                subtitle:
                    "Play subtle sounds when dictation starts and stops.",
                isOn: $soundFeedback
            )
        }
    }

    // MARK: - Divider

    private var divider: some View {

        Rectangle()
            .fill(
                Color.primary
                    .opacity(0.07)
            )
            .frame(height: 1)
            .padding(.leading, 42)
    }
}

// MARK: - Section

private struct NotificationSettingsSection<
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

// MARK: - Toggle Row

private struct NotificationToggleRow: View {

    let icon: String
    let title: String
    let subtitle: String

    @Binding var isOn: Bool

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 10
        ) {

            NotificationIcon(
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

// MARK: - Icon

private struct NotificationIcon: View {

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

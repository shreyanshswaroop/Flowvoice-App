import SwiftUI

struct ConnectorsSettingsView: View {

    @State private var slackConnected = false
    @State private var notionConnected = false
    @State private var driveConnected = false
    @State private var googleCalendarConnected = false
    @State private var zoomConnected = false
    @State private var teamsConnected = false

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 30
            ) {

                header

                connectorsSection
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

            Text("Connectors")
                .font(
                    .system(
                        size: 30,
                        weight: .regular,
                        design: .serif
                    )
                )

            Text(
                "Connect FlowVoice with the tools you already use."
            )
            .font(
                .system(size: 13)
            )
            .foregroundStyle(
                Color.secondary
            )
        }
    }

    // MARK: - Connectors

    private var connectorsSection: some View {

        ConnectorsSection(
            title: "Available integrations"
        ) {

            ConnectorRow(
                logo: "slack-logo",
                title: "Slack",
                subtitle:
                    "Send meeting notes and follow-ups directly to Slack.",
                isConnected: slackConnected
            ) {
                slackConnected.toggle()
            }

            connectorDivider

            ConnectorRow(
                logo: "notion-logo",
                title: "Notion",
                subtitle:
                    "Save FlowVoice meeting notes and summaries to Notion.",
                isConnected: notionConnected
            ) {
                notionConnected.toggle()
            }

            connectorDivider

            ConnectorRow(
                logo: "google-drive-logo",
                title: "Google Drive",
                subtitle:
                    "Export and sync notes with your Google Drive.",
                isConnected: driveConnected
            ) {
                driveConnected.toggle()
            }

            connectorDivider

            ConnectorRow(
                logo: "google-calendar-logo",
                title: "Google Calendar",
                subtitle:
                    "Sync meetings and automatically detect upcoming calls.",
                isConnected: googleCalendarConnected
            ) {
                googleCalendarConnected.toggle()
            }

            connectorDivider

            ConnectorRow(
                logo: "zoom-logo",
                title: "Zoom",
                subtitle:
                    "Use FlowVoice alongside your Zoom meetings.",
                isConnected: zoomConnected
            ) {
                zoomConnected.toggle()
            }

            connectorDivider

            ConnectorRow(
                logo: "microsoft-teams-logo",
                title: "Microsoft Teams",
                subtitle:
                    "Connect FlowVoice to your Microsoft Teams meetings.",
                isConnected: teamsConnected
            ) {
                teamsConnected.toggle()
            }
        }
    }

    // MARK: - Divider

    private var connectorDivider: some View {

        Rectangle()
            .fill(
                Color.primary
                    .opacity(0.07)
            )
            .frame(height: 1)
            .padding(.leading, 54)
    }
}

// MARK: - Section

private struct ConnectorsSection<
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

// MARK: - Connector Row

private struct ConnectorRow: View {

    let logo: String
    let title: String
    let subtitle: String
    let isConnected: Bool

    let action: () -> Void

    var body: some View {

        HStack(
            spacing: 12
        ) {

            connectorLogo

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

            Button {
                withAnimation(
                    .easeInOut(duration: 0.16)
                ) {
                    action()
                }
            } label: {

                Text(
                    isConnected
                    ? "Disconnect"
                    : "Connect"
                )
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
            .buttonStyle(.plain)
        }
        .padding(
            EdgeInsets(
                top: 12,
                leading: 12,
                bottom: 12,
                trailing: 14
            )
        )
    }

    // MARK: - Logo

    private var connectorLogo: some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 9,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.hoverSurface
            )

            Image(logo)
                .resizable()
                .scaledToFit()
                .padding(7)
        }
        .frame(
            width: 34,
            height: 34
        )
    }
}

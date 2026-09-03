import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var controller: FlowVoiceController
    @EnvironmentObject var authManager: AuthManager

    @Binding var showSettings: Bool

    @State private var isBackButtonHovering = false

    let selectedSection: SettingsSection

    var body: some View {

        ZStack {

            FlowVoiceTheme
                .pageBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {

                topBar
                    .zIndex(1)

                content
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSettings = false
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(
                            .system(
                                size: 10,
                                weight: .regular
                            )
                        )

                    Image(systemName: "house")
                        .font(
                            .system(
                                size: 13,
                                weight: .regular
                            )
                        )
                }
                .foregroundStyle(FlowVoiceTheme.secondaryText)
                .frame(
                    width: 46,
                    height: 28
                )
                .background {
                    Capsule()
                    .fill(
                        isBackButtonHovering
                        ? FlowVoiceTheme.selectedSurface
                        : FlowVoiceTheme.hoverSurface.opacity(0.7)
                    )
                }
                .overlay {
                    Capsule()
                    .stroke(
                        FlowVoiceTheme.hairline,
                        lineWidth: 0.8
                    )
                }
                .contentShape(
                    Capsule()
                )
            }
            .buttonStyle(.plain)
            .help("Back to FlowVoice")
            .onHover { isHovering in
                withAnimation(.easeOut(duration: 0.12)) {
                    isBackButtonHovering = isHovering
                }
            }

            Spacer()

            Text("Settings")
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(Color.secondary)

            Spacer()

            Color.clear
                .frame(
                    width: 46,
                    height: 28
                )
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .frame(height: 56)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {

        switch selectedSection {

        case .general:
            GeneralSettingsView()

        case .profile:
            ProfileSettingsView()

        case .calendar:
            CalendarSettingsView()

        case .notifications:
            NotificationSettingsView()

        case .connectors:
            ConnectorsSettingsView()

        case .getHelp:
            placeholder(
                title: "Get help",
                icon: "questionmark.circle"
            )

        case .workspaceGeneral:
            placeholder(
                title: "Workspace",
                icon: "building.2"
            )

        case .members:
            placeholder(
                title: "Members",
                icon: "person.2"
            )

        case .spaces:
            placeholder(
                title: "Spaces",
                icon: "folder"
            )

        case .analytics:
            placeholder(
                title: "Analytics",
                icon: "chart.xyaxis.line"
            )

        case .billing:
            placeholder(
                title: "Billing",
                icon: "creditcard"
            )

        case .referrals:
            placeholder(
                title: "Referrals",
                icon: "gift"
            )
        }
    }

    private func placeholder(
        title: String,
        icon: String
    ) -> some View {

        VStack(spacing: 14) {

            Image(systemName: icon)
                .font(
                    .system(
                        size: 28,
                        weight: .light
                    )
                )
                .foregroundStyle(
                    Color.secondary
                )

            Text(title)
                .font(
                    .system(
                        size: 28,
                        weight: .medium,
                        design: .serif
                    )
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

import SwiftUI

struct SettingsModalView: View {

    @EnvironmentObject var controller: FlowVoiceController
    @EnvironmentObject var authManager: AuthManager

    @Binding var selectedSection: SettingsSection
    @State private var searchText = ""

    var body: some View {

        HStack(spacing: 0) {

            settingsSidebar

            Divider()
                .overlay(
                    FlowVoiceTheme.divider
                )

            settingsContent
        }
        .frame(
            maxWidth: 980,
            maxHeight: 680
        )
        .background {

            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.elevatedSurface
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.strongHairline,
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.15),
            radius: 34,
            x: 0,
            y: 18
        )
    }

    // MARK: - Sidebar

    private var settingsSidebar: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            searchField
                .padding(.top, 22)

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    ForEach(
                        filteredSections
                    ) { section in

                        settingsSidebarRow(
                            section
                        )
                    }
                }
                .padding(
                    .horizontal,
                    12
                )
                .padding(
                    .top,
                    12
                )
            }
            .scrollIndicators(.hidden)

            Spacer()

            connectionStatus
        }
        .frame(width: 290)
        .background(
            FlowVoiceTheme.surface
        )
    }

    // MARK: - Search

    private var searchField: some View {

        HStack(spacing: 9) {

            Image(
                systemName: "magnifyingglass"
            )
            .font(
                .system(
                    size: 13,
                    weight: .medium
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.tertiaryText
            )

            TextField(
                "Search settings",
                text: $searchText
            )
            .textFieldStyle(.plain)
            .font(
                .system(
                    size: 13,
                    weight: .regular
                )
            )
        }
        .padding(
            .horizontal,
            12
        )
        .frame(height: 38)
        .background {

            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.inputSurface
            )
        }
        .overlay {

            RoundedRectangle(
                cornerRadius: 12,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        }
        .padding(
            .horizontal,
            14
        )
    }

    // MARK: - Filtered Sections

    private var filteredSections: [SettingsSection] {

        if searchText.isEmpty {
            return SettingsSection.allCases
        }

        return SettingsSection.allCases.filter {

            $0.title.localizedCaseInsensitiveContains(
                searchText
            )
        }
    }

    // MARK: - Sidebar Row

    private func settingsSidebarRow(
        _ section: SettingsSection
    ) -> some View {

        Button {

            withAnimation(
                .easeInOut(
                    duration: 0.15
                )
            ) {
                selectedSection = section
            }

        } label: {

            HStack(spacing: 11) {

                Image(
                    systemName: section.icon
                )
                .font(
                    .system(
                        size: 15,
                        weight: .medium
                    )
                )
                .frame(width: 20)

                Text(section.title)
                    .font(
                        .system(
                            size: 14,
                            weight:
                                selectedSection == section
                                ? .semibold
                                : .regular
                        )
                    )

                Spacer()
            }
            .foregroundStyle(
                selectedSection == section
                    ? FlowVoiceTheme.primaryText
                    : FlowVoiceTheme.secondaryText
            )
            .padding(
                .horizontal,
                12
            )
            .frame(height: 40)
            .background {

                if selectedSection == section {

                    RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
                    .fill(
                        FlowVoiceTheme.selectedSurface
                    )
                }
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Connection

    private var connectionStatus: some View {

        HStack(spacing: 8) {

            Circle()
                .fill(
                    controller.isConnected
                        ? Color.green
                        : Color.gray.opacity(0.45)
                )
                .frame(
                    width: 7,
                    height: 7
                )

            Text(
                controller.isConnected
                    ? "Connected"
                    : "Disconnected"
            )
            .font(
                .system(
                    size: 11,
                    weight: .medium
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.tertiaryText
            )

            Spacer()
        }
        .padding(
            .horizontal,
            22
        )
        .padding(
            .bottom,
            20
        )
    }

    // MARK: - Settings Content

    @ViewBuilder
    private var settingsContent: some View {

        switch selectedSection {

        case .general:

            GeneralSettingsView()

        case .voice:

            VoiceSettingsView()

        case .account:

            AccountSettingsView()

        case .keyboard:

            KeyboardSettingsView()

        case .storage:

            StorageSettingsView()

        case .privacy:

            PrivacySettingsView()
        }
    }
}

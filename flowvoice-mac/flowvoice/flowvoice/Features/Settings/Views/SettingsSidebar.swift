import SwiftUI

struct SettingsSidebar: View {

    @EnvironmentObject var authManager: AuthManager

    @Binding var selectedSection: SettingsSection
    @Binding var showSettings: Bool

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            accountHeader

            Spacer()
                .frame(height: 22)

            personalNavigation

            Spacer()
                .frame(height: 18)

            workspaceNavigation

            Spacer()

            signOutButton
        }
        .padding(.horizontal, 14)
        .padding(.top, 44)
        .padding(.bottom, 18)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            FlowVoiceTheme.sidebarBackground
        )
    }

    // MARK: - Account Header

    private var accountHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 3
        ) {

            Text(userName)
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.primary
                )
                .lineLimit(1)

            Text(userEmail)
                .font(
                    .system(
                        size: 12,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    Color.secondary
                )
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Personal Navigation

    private var personalNavigation: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            ForEach(
                SettingsSection.personalSections
            ) { section in

                settingsRow(
                    section
                )
            }
        }
    }

    // MARK: - Workspace

    private var workspaceNavigation: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Workspace")
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.secondary
                )
                .padding(
                    .horizontal,
                    8
                )

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                ForEach(
                    SettingsSection.workspaceSections
                ) { section in

                    settingsRow(
                        section
                    )
                }
            }
        }
    }

    // MARK: - Row

    private func settingsRow(
        _ section: SettingsSection
    ) -> some View {

        SettingsSidebarRow(
            section: section,
            isSelected:
                selectedSection == section
        ) {

            withAnimation(
                .easeInOut(
                    duration: 0.15
                )
            ) {

                selectedSection =
                    section
            }
        }
    }

    // MARK: - Sign Out

    private var signOutButton: some View {

        Button {

            authManager.logout()

        } label: {

            HStack(
                spacing: 10
            ) {

                Image(
                    systemName:
                        "rectangle.portrait.and.arrow.right"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )

                Text("Sign out")
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )

                Spacer()
            }
            .foregroundStyle(
                Color.red
            )
            .padding(
                .horizontal,
                10
            )
            .frame(
                height: 34
            )
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - User Data

    private var userName: String {

        authManager
            .user?
            .name ??
            "FlowVoice User"
    }

    private var userEmail: String {

        authManager
            .user?
            .email ??
            ""
    }
}

// MARK: - Settings Sidebar Row

private struct SettingsSidebarRow: View {

    let section: SettingsSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {

        Button(
            action: action
        ) {

            HStack(
                spacing: 10
            ) {

                Image(
                    systemName:
                        section.icon
                )
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .symbolRenderingMode(
                    .hierarchical
                )
                .frame(
                    width: 20
                )

                Text(
                    section.title
                )
                .font(
                    .system(
                        size: 13,
                        weight: .regular
                    )
                )

                Spacer()
            }
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .opacity(
                isSelected
                    ? 1.0
                    : isHovering
                        ? 0.82
                        : 0.46
            )
            .padding(
                .horizontal,
                11
            )
            .frame(
                height: 30
            )
            .background {
                rowBackground
            }
            .contentShape(
                Rectangle()
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in

            withAnimation(
                .easeOut(
                    duration: 0.12
                )
            ) {

                isHovering =
                    hovering
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var rowBackground: some View {

        if isHovering && !isSelected {

            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.hoverSurface
            )
        }
    }
}

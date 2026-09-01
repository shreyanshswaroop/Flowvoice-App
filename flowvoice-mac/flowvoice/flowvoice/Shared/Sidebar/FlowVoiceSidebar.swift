import SwiftUI

struct FlowVoiceSidebar: View {

    @EnvironmentObject var controller: FlowVoiceController

    @Binding var selectedTab: SidebarTab
    @Binding var showSettings: Bool
    @Binding var showHelp: Bool
    @Binding var isCollapsed: Bool

    @State private var isHeaderIconHovered = false

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            header

            Spacer()
                .frame(
                    height: isCollapsed ? 10 : 14
                )

            primaryNavigation

            Spacer()

            bottomNavigation
        }
        .padding(
            .horizontal,
            isCollapsed ? 8 : 12
        )
        .padding(.top, 14)
        .padding(.bottom, 14)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            FlowVoiceTheme.sidebarBackground
        )
        .onChange(of: isCollapsed) { _, _ in
            isHeaderIconHovered = false
        }
    }

    // MARK: - Header

    private var header: some View {

        HStack(spacing: 10) {

            // MARK: Logo / Expand when collapsed

            Button {

                if isCollapsed {

                    withAnimation(
                        .easeInOut(
                            duration: 0.22
                        )
                    ) {
                        isCollapsed = false
                    }
                }

            } label: {

                ZStack {

                    if isCollapsed &&
                        isHeaderIconHovered {

                        Image(
                            systemName: "sidebar.right"
                        )
                        .font(
                            .system(
                                size: 17,
                                weight: .medium
                            )
                        )
                        .transition(.opacity)

                    } else {

                        Image(
                            systemName: "waveform"
                        )
                        .font(
                            .system(
                                size: 18,
                                weight: .semibold
                            )
                        )
                        .transition(.opacity)
                    }
                }
                .foregroundStyle(
                    Color.primary
                )
                .frame(
                    width: 42,
                    height: 42
                )
                .contentShape(
                    Rectangle()
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in

                if isCollapsed {

                    withAnimation(
                        .easeInOut(
                            duration: 0.12
                        )
                    ) {
                        isHeaderIconHovered = hovering
                    }

                } else {

                    isHeaderIconHovered = false
                }
            }
            .help(
                isCollapsed
                    ? "Expand sidebar"
                    : ""
            )

            // MARK: App Name

            if !isCollapsed {

                HStack(spacing: 3) {

                    Text("Hush")
                        .font(
                            .system(
                                size: 28,
                                weight: .regular,
                                design: .serif
                            )
                        )

                    Text("Note")
                        .font(
                            .system(
                                size: 29,
                                weight: .regular,
                                design: .serif
                            )
                        )
                        .italic()
                }
                .foregroundStyle(
                    Color.primary
                )
                .lineLimit(1)
                .fixedSize(
                    horizontal: true,
                    vertical: false
                )

                Spacer(
                    minLength: 0
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment:
                isCollapsed
                ? .center
                : .leading
        )
        .frame(
            height: 54
        )
    }

    // MARK: - Primary Navigation

    private var primaryNavigation: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            ForEach(
                SidebarTab.primaryTabs
            ) { tab in

                SidebarRow(
                    tab: tab,
                    isSelected:
                        !showSettings &&
                        !showHelp &&
                        selectedTab == tab,
                    isCollapsed:
                        isCollapsed
                ) {

                    withAnimation(
                        .easeInOut(
                            duration: 0.18
                        )
                    ) {

                        showSettings = false
                        showHelp = false
                        selectedTab = tab
                    }
                }
            }
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            SidebarRow(
                tab: .settings,
                isSelected: showSettings,
                isCollapsed: isCollapsed
            ) {

                withAnimation(
                    .spring(
                        response: 0.30,
                        dampingFraction: 0.88
                    )
                ) {

                    showHelp = false
                    showSettings = true
                }
            }

            SidebarRow(
                tab: .help,
                isSelected: showHelp,
                isCollapsed: isCollapsed
            ) {

                withAnimation(
                    .spring(
                        response: 0.30,
                        dampingFraction: 0.88
                    )
                ) {

                    showSettings = false
                    showHelp = true
                }
            }
        }
    }
}

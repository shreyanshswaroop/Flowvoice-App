import SwiftUI
import AppKit

struct AppSidebar: View {

    @EnvironmentObject var controller: FlowVoiceController
    @Binding var selectedTab: SidebarTab

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            HStack(spacing: 10) {

                ZStack {

                    RoundedRectangle(
                        cornerRadius: 12,
                        style: .continuous
                    )
                    .fill(FlowVoiceTheme.accentButton)

                    Image(
                        systemName: "waveform"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.accentButtonText
                    )
                }
                .frame(
                    width: 34,
                    height: 34
                )

                Text("FlowVoice")
                    .font(
                        .system(
                            size: 24,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )
            }
            .padding(.horizontal, 22)
            .padding(.top, 54)
            .padding(.bottom, 26)

            // MARK: - Primary Navigation

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                ForEach(
                    SidebarTab.primaryTabs
                ) { tab in

                    SidebarRow(
                        tab: tab,
                        isSelected:
                            selectedTab == tab,
                        isCollapsed: false
                    ) {

                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 14)

            Spacer(minLength: 20)

            // MARK: - Secondary Navigation

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                ForEach(
                    SidebarTab.secondaryTabs
                ) { tab in

                    SidebarRow(
                        tab: tab,
                        isSelected:
                            selectedTab == tab,
                        isCollapsed: false
                    ) {

                        selectedTab = tab
                    }
                }
            }
            .padding(.horizontal, 14)

            Spacer(minLength: 18)

            // MARK: - Footer

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.surface
                )
                .overlay(

                    VStack(
                        alignment: .leading,
                        spacing: 8
                    ) {

                        Text("FlowVoice")
                            .font(
                                .system(
                                    size: 13,
                                    weight: .semibold
                                )
                            )

                        Text(
                            "Use your voice across your Mac with one shortcut."
                        )
                        .font(
                            .system(
                                size: 12
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                    }
                    .padding(14)
                )
                .frame(height: 92)

                HStack(spacing: 10) {

                    Circle()
                        .fill(
                            controller.isConnected
                                ? Color.green
                                : Color.gray.opacity(0.5)
                        )
                        .frame(
                            width: 8,
                            height: 8
                        )

                    Text(
                        controller.isConnected
                            ? "Connected"
                            : "Disconnected"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .frame(width: 238)
        .background(
            FlowVoiceTheme.sidebarBackground
        )
    }
}

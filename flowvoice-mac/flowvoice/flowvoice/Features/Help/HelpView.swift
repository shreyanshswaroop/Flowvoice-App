import SwiftUI

struct HelpView: View {

    @Environment(\.openURL) private var openURL

    let openSettingsSection: (SettingsSection) -> Void

    private let helpCenterURL = URL(
        string: "https://yourwebsite.com/help"
    )!

    private let supportURL = URL(
        string: "https://yourwebsite.com/support"
    )!

    private let salesURL = URL(
        string: "https://yourwebsite.com/contact"
    )!

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 0
            ) {

                Text("Help")
                    .font(
                        .system(
                            size: 28,
                            weight: .regular,
                            design: .serif
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )
                    .padding(.bottom, 24)

                Divider()
                    .overlay(
                        FlowVoiceTheme.divider
                    )

                VStack(
                    alignment: .leading,
                    spacing: 0
                ) {

                    sectionTitle("Essentials")

                    helpRow(
                        icon: "command",
                        title: "Shortcuts"
                    ) {
                        openSettingsSection(.keyboard)
                    }

                    helpRow(
                        icon: "mic",
                        title: "Microphone"
                    ) {
                        openSettingsSection(.voice)
                    }

                    helpRow(
                        icon: "globe",
                        title: "Languages"
                    ) {
                        openSettingsSection(.general)
                    }

                    Divider()
                        .overlay(
                            FlowVoiceTheme.divider
                        )
                        .padding(.vertical, 16)

                    sectionTitle("Get in touch")

                    helpRow(
                        icon: "cross.case",
                        title: "Help Center"
                    ) {
                        openURL(helpCenterURL)
                    }

                    helpRow(
                        icon: "message.badge",
                        title: "Talk to support"
                    ) {
                        openURL(supportURL)
                    }

                    helpRow(
                        icon: "briefcase",
                        title: "Contact sales"
                    ) {
                        openURL(salesURL)
                    }
                }
            }
            .padding(
                .horizontal,
                30
            )
            .padding(
                .vertical,
                26
            )
        }
        .scrollIndicators(.hidden)
    }

    private func sectionTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.secondaryText
            )
            .padding(.top, 18)
            .padding(.bottom, 8)
    }

    private func helpRow(
        icon: String,
        title: String,
        action: @escaping () -> Void
    ) -> some View {

        Button(action: action) {

            HStack(spacing: 14) {

                Image(systemName: icon)
                    .font(
                        .system(
                            size: 16,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )
                    .frame(width: 22)

                Text(title)
                    .font(
                        .system(
                            size: 15,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(
                    .system(
                        size: 10,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.mutedText
                )
            }
            .padding(
                .horizontal,
                12
            )
            .frame(height: 46)
            .contentShape(Rectangle())
        }
        .buttonStyle(
            HelpRowButtonStyle()
        )
    }
}

private struct HelpRowButtonStyle: ButtonStyle {

    @State private var isHovered = false

    func makeBody(
        configuration: Configuration
    ) -> some View {

        configuration.label
            .background {

                RoundedRectangle(
                    cornerRadius: 11,
                    style: .continuous
                )
                .fill(
                    configuration.isPressed
                        ? FlowVoiceTheme.pressedSurface
                        : isHovered
                            ? FlowVoiceTheme.hoverSurface
                            : Color.clear
                )
            }
            .onHover { hovering in

                withAnimation(
                    .easeInOut(
                        duration: 0.12
                    )
                ) {
                    isHovered = hovering
                }
            }
    }
}

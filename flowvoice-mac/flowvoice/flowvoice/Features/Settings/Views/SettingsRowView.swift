import SwiftUI

struct SettingsSelectRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)
                .font(
                    .system(
                        size: 14,
                        weight: .regular
                    )
                )

            Spacer()

            HStack(spacing: 8) {

                Text(value)
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )

                Image(
                    systemName: "chevron.down"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
            }
            .font(
                .system(
                    size: 14
                )
            )
        }
        .padding(.vertical, 14)
    }
}

struct SettingsToggleRow: View {

    let title: String
    let subtitle: String?

    @Binding var isOn: Bool

    init(
        title: String,
        subtitle: String? = nil,
        isOn: Binding<Bool>
    ) {

        self.title = title
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {

        HStack(
            alignment: .center,
            spacing: 20
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(title)
                    .font(
                        .system(
                            size: 14,
                            weight: .regular
                        )
                    )

                if let subtitle {

                    Text(subtitle)
                        .font(
                            .system(
                                size: 12,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.tertiaryText
                        )
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
            }

            Spacer()

            Toggle(
                "",
                isOn: $isOn
            )
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.vertical, 13)
    }
}

struct SettingsInfoRow: View {

    let title: String
    let value: String

    var body: some View {

        HStack {

            Text(title)
                .font(
                    .system(
                        size: 14
                    )
                )

            Spacer()

            Text(value)
                .font(
                    .system(
                        size: 14
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
        }
        .padding(.vertical, 14)
    }
}

struct SettingsActionRow: View {

    let title: String
    var tint: Color = FlowVoiceTheme.primaryText

    var body: some View {

        Button {

            // Functionality later

        } label: {

            HStack {

                Text(title)

                Spacer()

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
            }
            .font(
                .system(
                    size: 14,
                    weight: .regular
                )
            )
            .foregroundStyle(tint)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

@ViewBuilder
func settingsPage<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
) -> some View {

    ScrollView {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            Text(title)
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
                .padding(
                    .bottom,
                    24
                )

            Divider()
                .overlay(
                    FlowVoiceTheme.divider
                )

            VStack(
                spacing: 0
            ) {

                content()
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
    .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .topLeading
    )
}

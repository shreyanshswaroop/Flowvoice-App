import SwiftUI

struct ExternalAuthView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {

        ZStack {

            FlowVoiceTheme.pageBackground
                .ignoresSafeArea()

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                HStack {

                    Button {
                        authManager
                            .isExternalAuthInProgress = false

                        AppWindowManager.shared
                            .showAuthWindow()

                    } label: {

                        Image(
                            systemName: "chevron.left"
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .frame(
                            width: 30,
                            height: 30
                        )
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }

                Spacer()

                VStack(
                    alignment: .leading,
                    spacing: 14
                ) {

                    RoundedRectangle(
                        cornerRadius: 11,
                        style: .continuous
                    )
                    .fill(
                        FlowVoiceTheme.accentButton
                    )
                    .frame(
                        width: 42,
                        height: 42
                    )
                    .overlay {

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
                            FlowVoiceTheme
                                .accentButtonText
                        )
                    }

                    Text(
                        "Sign in to FlowVoice"
                    )
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

                    Text(
                        "Finish signing in with Google in your browser."
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        .secondary
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                    HStack(spacing: 9) {

                        ProgressView()
                            .controlSize(.small)

                        Text(
                            "Waiting for Google…"
                        )
                        .font(
                            .system(
                                size: 13,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            .secondary
                        )
                    }
                    .padding(.top, 4)
                }

                Spacer()
            }
            .padding(26)
        }
    }
}

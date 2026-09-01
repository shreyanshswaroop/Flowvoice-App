import SwiftUI
import AppKit

struct AuthView: View {

    @EnvironmentObject var authManager: AuthManager

    var body: some View {

        ZStack {

            background

            VStack {

                Spacer()

                browserAuthPanel

                Spacer()
            }
            .padding(.horizontal, 36)
            .padding(.vertical, 34)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }

    // MARK: - Background

    private var background: some View {

        GeometryReader { proxy in

            ZStack {

                Image("AuthLandscape")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.18),
                        Color.black.opacity(0.42),
                        FlowVoiceTheme
                            .pageBackground
                            .opacity(0.70)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                RadialGradient(
                    colors: [
                        Color.white.opacity(0.07),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 40,
                    endRadius: 500
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Browser Auth

    private var browserAuthPanel: some View {

        VStack(
            alignment: .center,
            spacing: 18
        ) {

            brandHeader

            VStack(spacing: 8) {
                Text("Sign in with your browser")
                    .font(
                        .system(
                            size: 28,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Text("FlowVoice will bring you back here automatically after sign in.")
                    .font(
                        .system(
                            size: 14,
                            weight: .regular
                        )
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 300)
            }

            if let error =
                authManager.errorMessage {

                Text(error)
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.red)
            }

            Button {
                authManager.openWebsiteAuth()
            } label: {
                HStack(spacing: 8) {
                    Text("Open sign in")

                    Image(systemName: "arrow.up.forward")
                }
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 46)
                .foregroundStyle(
                    FlowVoiceTheme.accentButtonText
                )
                .background(
                    FlowVoiceTheme.accentButton,
                    in:
                        RoundedRectangle(
                            cornerRadius: 12,
                            style: .continuous
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(
            .horizontal,
            28
        )
        .padding(
            .vertical,
            26
        )
        .frame(
            width: 430
        )
        .background {

            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(
                .ultraThinMaterial
            )
        }
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
            color: .black.opacity(0.12),
            radius: 28,
            x: 0,
            y: 14
        )
    }

    // MARK: - Brand Header

    private var brandHeader: some View {

        HStack(spacing: 12) {

            RoundedRectangle(
                cornerRadius: 10,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.accentButton
            )
            .frame(
                width: 38,
                height: 38
            )
            .overlay {

                Image(
                    systemName: "waveform"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.accentButtonText
                )
            }

            HStack(spacing: 2) {

                Text("Flow")
                    .font(
                        .system(
                            size: 27,
                            weight: .regular,
                            design: .serif
                        )
                    )

                Text("Voice")
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
                FlowVoiceTheme.primaryText
            )

            Spacer()
        }
    }
}

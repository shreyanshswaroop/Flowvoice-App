import SwiftUI

struct DictationDashboardView: View {

    @EnvironmentObject var authManager: AuthManager

    let history: [DictationEntry]
    let onDelete: (DictationEntry) -> Void

    private let pageBackground =
        FlowVoiceTheme.pageBackground

    private let warmOrange =
        Color(
            red: 0.96,
            green: 0.53,
            blue: 0.19
        )

    private let softGreen =
        Color(
            red: 0.35,
            green: 0.63,
            blue: 0.39
        )

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 28
            ) {
                
                

                heroSection

                quickStats

                historySection

                featureSection
            }
            .padding(.horizontal, 34)
            .padding(.top, 28)
            .padding(.bottom, 50)
        }
        .scrollIndicators(.hidden)
        .background(
            pageBackground
        )
    }

    // MARK: - Hero

    private var heroSection: some View {

        ZStack {

            heroBackground

            HStack(
                alignment: .center,
                spacing: 20
            ) {

                heroCopy
                    .frame(
                        maxWidth: 760,
                        alignment: .leading
                    )
                    .layoutPriority(1)

                Spacer(minLength: 0)

                readyCard
                    .offset(x: 14)
            }
            .padding(.horizontal, 34)
            .padding(.vertical, 26)
        }
        .frame(height: 250)
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
            color: .black.opacity(0.03),
            radius: 14,
            x: 0,
            y: 8
        )
    }

    private var heroBackground: some View {

        GeometryReader { proxy in

            ZStack {

                Image("FlowClouds")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: proxy.size.width,
                        height: proxy.size.height
                    )
                    .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.25),
                        pageBackground.opacity(0.35),
                        pageBackground.opacity(0.72)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .frame(
                width: proxy.size.width,
                height: proxy.size.height
            )
        }
    }

    // MARK: - Hero Copy

    private var heroCopy: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Hi \(firstName),")
                    .font(
                        .custom("Avenir Next", size: 42)
                        .weight(.medium)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Text("ready to get back in the flow?")
                    .font(
                        .custom("GrandHotel", size: 34)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .fixedSize(
                        horizontal: true,
                        vertical: false
                    )
            }

            Text(
                "Capture what’s on your mind, dictate anywhere, and keep moving without breaking your focus."
            )
            .font(
                .custom("Avenir Next", size: 14)
            )
            .foregroundStyle(
                FlowVoiceTheme.secondaryText
            )
            .lineSpacing(3)
            .frame(
                maxWidth: 560,
                alignment: .leading
            )

            shortcutBadge
                .padding(.top, 2)
        }
    }

    private var firstName: String {

        guard let name = authManager.user?.name,
              !name.isEmpty
        else {
            return "there"
        }

        return name
            .split(separator: " ")
            .first
            .map(String.init)
            ?? name
    }

    // MARK: - Shortcut Badge

    private var shortcutBadge: some View {

        HStack(
            spacing: 9
        ) {

            Image(
                systemName: "waveform"
            )
            .font(
                .system(
                    size: 11,
                    weight: .semibold
                )
            )

            Text("Hold ⌥ Space and speak")
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                    .weight(.medium)
                )
        }
        .foregroundStyle(
            FlowVoiceTheme.secondaryText
        )
        .padding(
            .horizontal,
            13
        )
        .padding(
            .vertical,
            8
        )
        .background {

            Capsule()
                .fill(
                    FlowVoiceTheme.elevatedSurface.opacity(0.86)
                )
                .overlay {

                    Capsule()
                        .stroke(
                            FlowVoiceTheme.strongHairline,
                            lineWidth: 0.8
                        )
                }
        }
    }

    // MARK: - Ready Card

    private var readyCard: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            HStack(
                spacing: 6
            ) {

                Circle()
                    .fill(softGreen)
                    .frame(width: 6, height: 6)

                Text("READY")
                    .font(
                        .custom("Avenir Next", size: 8.5)
                        .weight(.semibold)
                    )
                    .tracking(1.2)
                    .foregroundStyle(
                        FlowVoiceTheme.tertiaryText
                    )
            }

            Text("Speak\nnaturally.")
                .font(
                    .custom("Avenir Next", size: 18)
                    .weight(.semibold)
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
                .lineSpacing(-1)

            Text("FlowVoice handles the rest.")
                .font(
                    .custom("Avenir Next", size: 9.5)
                )
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(
            width: 155,
            alignment: .leading
        )
        .background {

            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.elevatedSurface.opacity(0.94)
            )
        }
        .overlay {

            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.strongHairline,
                lineWidth: 1
            )
        }
        .shadow(
            color: .black.opacity(0.05),
            radius: 14,
            x: 0,
            y: 8
        )
    }

    // MARK: - Stats

    private var quickStats: some View {

        HStack(
            spacing: 12
        ) {

            statCard(
                eyebrow: "VOICE MEMORY",
                value: "\(totalWordCount)",
                label: "total words",
                icon: "text.quote",
                tint: warmOrange
            )

            statCard(
                eyebrow: "RECENT ACTIVITY",
                value: "\(history.count)",
                label: "dictations",
                icon: "clock.arrow.circlepath",
                tint: .blue
            )

            statCard(
                eyebrow: "FAST ACCESS",
                value: "⌥ Space",
                label: "shortcut",
                icon: "command",
                tint: softGreen
            )
        }
    }

    private func statCard(
        eyebrow: String,
        value: String,
        label: String,
        icon: String,
        tint: Color
    ) -> some View {

        HStack(
            spacing: 14
        ) {

            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                tint.opacity(0.10)
            )
            .frame(
                width: 42,
                height: 42
            )
            .overlay {

                Image(
                    systemName: icon
                )
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    tint
                )
            }

            VStack(
                alignment: .leading,
                spacing: 1
            ) {

                Text(eyebrow)
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 8.5
                        )
                        .weight(.semibold)
                    )
                    .tracking(1.5)
                    .foregroundStyle(
                        FlowVoiceTheme.mutedText
                    )

                HStack(
                    alignment: .firstTextBaseline,
                    spacing: 6
                ) {

                    Text(value)
                        .font(
                            .system(
                                size: 24,
                                weight: .regular,
                                design: .serif
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.primaryText
                        )
                        .lineLimit(1)

                    Text(label)
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 11.5
                            )
                            .weight(.medium)
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                        .lineLimit(1)
                }
            }

            Spacer(
                minLength: 0
            )
        }
        .padding(
            .horizontal,
            18
        )
        .padding(
            .vertical,
            10
        )
        .frame(
            maxWidth: .infinity,
            minHeight: 74
        )
        .background {

            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                .ultraThinMaterial
            )
            .overlay {

                LinearGradient(
                    colors: [
                        Color.white.opacity(0.38),
                        Color.white.opacity(0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 22,
                        style: .continuous
                    )
                )
            }
        }
        .overlay {

            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.strongHairline,
                lineWidth: 1
            )
        }
        .shadow(
            color: .white.opacity(0.22),
            radius: 2,
            x: 0,
            y: 1
        )
        .shadow(
            color: .black.opacity(0.05),
            radius: 14,
            x: 0,
            y: 8
        )
    }

    // MARK: - History

    private var historySection: some View {

        VStack(
            alignment: .leading,
            spacing: 13
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 1
                ) {

                    Text("VOICE HISTORY")
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 9
                            )
                            .weight(.semibold)
                        )
                        .tracking(1.7)
                        .foregroundStyle(
                            FlowVoiceTheme.mutedText
                        )

                    Text("Today")
                        .font(
                            .custom(
                                "GrandHotel",
                                size: 35
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.primaryText
                        )
                }

                Spacer()

                Image(
                    systemName: "magnifyingglass"
                )
                .font(
                    .system(
                        size: 14,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background {

                    Circle()
                        .fill(
                            FlowVoiceTheme.elevatedSurface
                        )
                }
            }

            VStack(
                spacing: 0
            ) {

                ForEach(
                    Array(
                        history.enumerated()
                    ),
                    id: \.element.id
                ) { index, item in

                    TranscriptRow(
                        item: item
                    ) {
                        onDelete(item)
                    }

                    if index != history.count - 1 {

                        Divider()
                            .overlay(
                                FlowVoiceTheme.divider
                            )
                            .padding(
                                .leading,
                                96
                            )
                    }
                }
            }
            .background {

                RoundedRectangle(
                    cornerRadius: 23,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.surface
                )
            }
            .overlay {

                RoundedRectangle(
                    cornerRadius: 23,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            }
            .shadow(
                color: .black.opacity(0.025),
                radius: 14,
                x: 0,
                y: 7
            )
        }
    }

    // MARK: - Feature Images

    private var featureSection: some View {

        HStack(
            spacing: 18
        ) {

            flowFeatureCard

            memoryFeatureCard
        }
        .frame(
            minHeight: 245
        )
    }

    // MARK: - Landscape

    private var flowFeatureCard: some View {

        ZStack(
            alignment: .bottomLeading
        ) {

            GeometryReader { proxy in

                Image(
                    "FlowLandscape"
                )
                .resizable()
                .scaledToFill()
                .frame(
                    width: proxy.size.width,
                    height: proxy.size.height
                )
                .offset(
                    x: 34,
                    y: 0
                )
                .clipped()
            }

            LinearGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.10),
                    Color.black.opacity(0.48)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    "FIND YOUR FLOW"
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 9
                    )
                    .weight(.semibold)
                )
                .tracking(1.8)
                .foregroundStyle(
                    Color.white.opacity(0.72)
                )

                Text(
                    "Speak. Keep moving."
                )
                .font(
                    .custom(
                        "GrandHotel",
                        size: 34
                    )
                )
                .foregroundStyle(
                    Color.white
                )

                Text(
                    "Your voice should disappear into the work, not interrupt it."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.78)
                )
                .frame(
                    maxWidth: 280,
                    alignment: .leading
                )
            }
            .padding(22)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 245
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 25,
                style: .continuous
            )
        )
    }

    // MARK: - Meeting Memory

    private var memoryFeatureCard: some View {

        ZStack(
            alignment: .bottomLeading
        ) {

            Image(
                "FlowMeeting"
            )
            .resizable()
            .scaledToFill()
            .frame(
                maxWidth: .infinity,
                minHeight: 245
            )
            .clipped()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.02),
                    Color.black.opacity(0.20),
                    Color.black.opacity(0.63)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    "VOICE MEMORY"
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 9
                    )
                    .weight(.semibold)
                )
                .tracking(1.8)
                .foregroundStyle(
                    Color.white.opacity(0.72)
                )

                Text(
                    "Remember what mattered."
                )
                .font(
                    .custom(
                        "GrandHotel",
                        size: 34
                    )
                )
                .foregroundStyle(
                    Color.white
                )

                Text(
                    "Keep conversations, thoughts and important words close."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    Color.white.opacity(0.78)
                )
                .frame(
                    maxWidth: 280,
                    alignment: .leading
                )
            }
            .padding(22)
        }
        .frame(
            maxWidth: .infinity
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 25,
                style: .continuous
            )
        )
    }

    // MARK: - Word Count

    private var totalWordCount: Int {

        history.reduce(0) {
            partial,
            item in

            partial +
            item.text
                .split(
                    separator: " "
                )
                .count
        }
    }
}

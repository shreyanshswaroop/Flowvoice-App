import SwiftUI

struct StatsCardView: View {

    let totalWordCount: Int
    let recentDictations: Int

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            statRow(
                title: "total words",
                value: "\(totalWordCount)"
            )
            .padding(.bottom, 18)

            Divider()
                .overlay(
                    FlowVoiceTheme.divider
                )

            statRow(
                title: "recent dictations",
                value: "\(recentDictations)"
            )
            .padding(.vertical, 18)

            Divider()
                .overlay(
                    FlowVoiceTheme.divider
                )

            statRow(
                title: "shortcut",
                value: "⌥ Space"
            )
            .padding(.top, 18)
        }
        .padding(22)
        .frame(
            width: 230,
            alignment: .leading
        )
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        )
        .shadow(
            color: .black.opacity(0.035),
            radius: 12,
            x: 0,
            y: 6
        )
    }

    private func statRow(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(value)
                .font(
                    .system(
                        size: 23,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            Text(title)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

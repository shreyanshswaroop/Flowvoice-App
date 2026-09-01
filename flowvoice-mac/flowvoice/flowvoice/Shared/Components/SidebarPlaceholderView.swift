import SwiftUI

struct SidebarPlaceholderView: View {

    let title: String
    let icon: String

    var body: some View {

        VStack(
            spacing: 12
        ) {

            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: 28,
                    weight: .regular
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.secondaryText
            )

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

            Text("Coming soon")
                .font(
                    .system(
                        size: 14,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
}

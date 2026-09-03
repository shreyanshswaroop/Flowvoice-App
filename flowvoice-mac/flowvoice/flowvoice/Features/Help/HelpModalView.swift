import SwiftUI

struct HelpModalView: View {

    let openSettingsSection: (SettingsSection) -> Void

    var body: some View {

        HelpView()
        .frame(
            width: 620,
            height: 420
        )
        .background {

            RoundedRectangle(
                cornerRadius: 28,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.elevatedSurface
            )
        }
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
            color: .black.opacity(0.15),
            radius: 34,
            x: 0,
            y: 18
        )
    }
}

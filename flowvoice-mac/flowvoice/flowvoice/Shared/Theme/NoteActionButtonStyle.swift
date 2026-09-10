import SwiftUI

struct NoteActionButtonStyle: ButtonStyle {
    var prominent = false
    var cornerRadius: CGFloat = 8

    func makeBody(configuration: Configuration) -> some View {
        ActionLabel(configuration: configuration, prominent: prominent, cornerRadius: cornerRadius)
    }

    private struct ActionLabel: View {
        let configuration: ButtonStyle.Configuration
        let prominent: Bool
        let cornerRadius: CGFloat
        @State private var hovered = false
        @Environment(\.isEnabled) private var isEnabled
        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(prominent ? FlowVoiceTheme.accentButtonText : FlowVoiceTheme.primaryText)
                        .opacity(isEnabled && (hovered || configuration.isPressed)
                                 ? (configuration.isPressed ? 0.20 : 0.10) : 0)
                        .allowsHitTesting(false)
                }
                .opacity(isEnabled ? 1 : 0.5)
                .onHover { hovered = $0 }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: hovered)
                .animation(reduceMotion ? nil : .easeOut(duration: 0.08), value: configuration.isPressed)
        }
    }
}

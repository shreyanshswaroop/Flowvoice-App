import SwiftUI
import AppKit

struct TranscriptRow: View {

    let item: DictationEntry
    let onDelete: () -> Void

    @State private var didCopy = false
    @State private var isHovered = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {

        HStack(spacing: 18) {

            Image(systemName: "waveform")
                .font(.system(size: 17))
                .foregroundStyle(FlowVoiceTheme.secondaryText)
                .frame(width: 38, height: 38)
                .background(FlowVoiceTheme.selectedSurface, in: RoundedRectangle(cornerRadius: 8))

            Text(item.text)
                .font(
                    .system(
                        size: 16,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .textSelection(.enabled)

            Text(item.createdAt.map { $0.formatted(date: .omitted, time: .shortened) } ?? item.time)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
                .frame(
                    width: 78,
                    alignment: .leading
                )

            HStack(spacing: 4) {

                // Copy
                Button {
                    copyText()
                } label: {

                    Image(
                        systemName:
                            didCopy
                            ? "checkmark"
                            : "doc.on.doc"
                    )
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
                }
                .buttonStyle(NoteActionButtonStyle())
                .help(
                    didCopy
                    ? "Copied"
                    : "Copy"
                )

                // More menu
                Menu {

                    Button {
                        copyText()
                    } label: {

                        Label(
                            "Copy",
                            systemImage: "doc.on.doc"
                        )
                    }

                    Divider()

                    Button(
                        role: .destructive
                    ) {
                        onDelete()
                    } label: {

                        Label(
                            "Delete Dictation",
                            systemImage: "trash"
                        )
                    }

                } label: {

                    Image(
                        systemName: "ellipsis"
                    )
                    .frame(
                        width: 36,
                        height: 36
                    )
                    .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .font(
                .system(
                    size: 14,
                    weight: .medium
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.tertiaryText
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(isHovered ? FlowVoiceTheme.hoverSurface : .clear,
                    in: RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onHover { isHovered = $0 }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: isHovered)
    }

    // MARK: - Copy

    private func copyText() {

        let pasteboard =
            NSPasteboard.general

        pasteboard.clearContents()

        pasteboard.setString(
            item.text,
            forType: .string
        )

        withAnimation(
            .easeInOut(
                duration: 0.15
            )
        ) {
            didCopy = true
        }

        DispatchQueue.main
            .asyncAfter(
                deadline: .now() + 1.2
            ) {

                withAnimation(
                    .easeInOut(
                        duration: 0.15
                    )
                ) {
                    didCopy = false
                }
            }
    }
}

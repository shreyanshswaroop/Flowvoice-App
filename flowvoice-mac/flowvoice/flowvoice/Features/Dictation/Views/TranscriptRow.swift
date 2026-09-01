import SwiftUI
import AppKit

struct TranscriptRow: View {

    let item: DictationEntry
    let onDelete: () -> Void

    @State private var didCopy = false

    var body: some View {

        HStack(spacing: 18) {

            Text(item.time)
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

            HStack(spacing: 14) {

                // Future playback
                Button {

                } label: {

                    Image(
                        systemName: "play"
                    )
                }
                .buttonStyle(.plain)

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
                }
                .buttonStyle(.plain)
                .help(
                    didCopy
                    ? "Copied"
                    : "Copy"
                )

                // Future flag feature
                Button {

                } label: {

                    Image(
                        systemName: "flag"
                    )
                }
                .buttonStyle(.plain)

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
                        width: 18,
                        height: 22
                    )
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
        .padding(
            .horizontal,
            18
        )
        .padding(
            .vertical,
            18
        )
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

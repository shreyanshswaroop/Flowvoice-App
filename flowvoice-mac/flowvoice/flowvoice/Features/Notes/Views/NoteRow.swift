import SwiftUI

struct NoteRow: View {

    let note: Note
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {

        Button {
            onOpen()
        } label: {

            HStack(
                spacing: 16
            ) {

                Image(
                    systemName: "note.text"
                )
                .font(
                    .system(
                        size: 15,
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
                .background(
                    Circle()
                        .fill(
                            FlowVoiceTheme.selectedSurface
                        )
                )

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    HStack(
                        spacing: 8
                    ) {

                        Text(note.title)
                            .font(
                                .custom(
                                    "Avenir Next",
                                    size: 14
                                )
                                .weight(.semibold)
                            )
                            .foregroundStyle(
                                FlowVoiceTheme.primaryText
                            )

                        if hasSummary {

                            HStack(
                                spacing: 4
                            ) {

                                Image(
                                    systemName: "sparkles"
                                )
                                .font(
                                    .system(
                                        size: 8,
                                        weight: .semibold
                                    )
                                )

                                Text("AI SUMMARY")
                                    .font(
                                        .custom(
                                            "Avenir Next",
                                            size: 7.5
                                        )
                                        .weight(.semibold)
                                    )
                                    .tracking(0.8)
                            }
                            .foregroundStyle(
                                Color.purple.opacity(0.72)
                            )
                            .padding(
                                .horizontal,
                                7
                            )
                            .padding(
                                .vertical,
                                3
                            )
                            .background(
                                Capsule()
                                    .fill(
                                        Color.purple.opacity(
                                            0.07
                                        )
                                    )
                            )
                        }
                    }

                    Text(note.transcript)
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 11
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                        .lineLimit(1)
                }

                Spacer()

                if let duration =
                    note.durationSeconds {

                    Text(
                        formattedDuration(
                            duration
                        )
                    )
                    .font(
                        .system(
                            size: 11,
                            weight: .medium,
                            design: .monospaced
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.tertiaryText
                    )
                }

                Menu {

                    Button {
                        onOpen()
                    } label: {

                        Label(
                            "Open",
                            systemImage:
                                "doc.text.magnifyingglass"
                        )
                    }

                    Divider()

                    Button(
                        role: .destructive
                    ) {
                        onDelete()
                    } label: {

                        Label(
                            "Delete",
                            systemImage: "trash"
                        )
                    }

                } label: {

                    Image(
                        systemName: "ellipsis"
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.tertiaryText
                    )
                    .frame(
                        width: 24,
                        height: 24
                    )
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(
                .horizontal,
                18
            )
            .padding(
                .vertical,
                16
            )
        }
        .buttonStyle(.plain)
    }

    private var hasSummary: Bool {

        guard let summary =
            note.summary?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )
        else {
            return false
        }

        return !summary.isEmpty
    }

    private func formattedDuration(
        _ seconds: Int
    ) -> String {

        let minutes =
            seconds / 60

        let remainingSeconds =
            seconds % 60

        return String(
            format: "%d:%02d",
            minutes,
            remainingSeconds
        )
    }
}

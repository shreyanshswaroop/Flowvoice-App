import SwiftUI
import AppKit

struct NoteDetailView: View {

    let note: Note

    let onClose: () -> Void

    let onNoteUpdated:
        (Note) -> Void

    @State private var currentNote: Note

    @State private var didCopy = false

    @State private var isGeneratingSummary = false

    @State private var summaryError: String?

    init(
        note: Note,
        onClose: @escaping () -> Void,
        onNoteUpdated:
            @escaping (Note) -> Void
    ) {

        self.note = note

        self.onClose = onClose

        self.onNoteUpdated =
            onNoteUpdated

        _currentNote =
            State(
                initialValue: note
            )
    }

    var body: some View {

        ZStack {

            FlowVoiceTheme.windowBackground
                .opacity(0.72)
                .ignoresSafeArea()
                .onTapGesture {

                    onClose()
                }

            VStack(
                alignment: .leading,
                spacing: 20
            ) {

                header

                Divider()
                    .overlay(
                        FlowVoiceTheme.divider
                    )

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 24
                    ) {

                        summaryArea

                        transcriptSection
                    }
                    .frame(
                        maxWidth: .infinity,
                        alignment: .leading
                    )
                }

                bottomBar
            }
            .padding(26)
            .frame(
                width: 680,
                height: 620
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 24,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.elevatedSurface
                )
            )
            .shadow(
                color:
                    .black.opacity(0.15),
                radius: 30,
                x: 0,
                y: 16
            )
        }
    }

    // MARK: - Header

    private var header:
        some View {

        HStack {

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    currentNote.title
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 28
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

                HStack(
                    spacing: 10
                ) {

                    if let duration =
                        currentNote
                            .durationSeconds {

                        Label(
                            formattedDuration(
                                duration
                            ),
                            systemImage:
                                "clock"
                        )
                    }

                    Text(
                        formattedDate(
                            currentNote
                                .createdAt
                        )
                    )

                    if !currentNote
                        .segments
                        .isEmpty {

                        HStack(
                            spacing: 4
                        ) {

                            Image(
                                systemName:
                                    "person.2"
                            )

                            Text(
                                "\(speakerCount) speakers"
                            )
                        }
                    }
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )
            }

            Spacer()

            Button {

                onClose()

            } label: {

                Image(
                    systemName:
                        "xmark"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
                .frame(
                    width: 30,
                    height: 30
                )
                .background(
                    Circle()
                        .fill(
                            FlowVoiceTheme.selectedSurface
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Speaker Count

    private var speakerCount:
        Int {

        Set(
            currentNote
                .segments
                .map {
                    $0.speaker
                }
        )
        .count
    }

    // MARK: - Summary Area

    @ViewBuilder
    private var summaryArea:
        some View {

        if hasGeneratedSummary {

            VStack(
                alignment: .leading,
                spacing: 14
            ) {

                HStack {

                    HStack(
                        spacing: 6
                    ) {

                        Image(
                            systemName:
                                "sparkles"
                        )

                        Text(
                            "AI INSIGHTS"
                        )
                    }
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 9
                        )
                        .weight(.semibold)
                    )
                    .tracking(1.4)
                    .foregroundStyle(
                        Color.purple.opacity(
                            0.7
                        )
                    )

                    Spacer()

                    Button {

                        generateSummary()

                    } label: {

                        HStack(
                            spacing: 5
                        ) {

                            if isGeneratingSummary {

                                ProgressView()
                                    .controlSize(
                                        .mini
                                    )

                            } else {

                                Image(
                                    systemName:
                                        "arrow.clockwise"
                                )

                                Text(
                                    "Regenerate"
                                )
                            }
                        }
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 10
                            )
                            .weight(.medium)
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.tertiaryText
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(
                        isGeneratingSummary
                    )
                }

                insightCard {

                    summarySection
                }

                if !currentNote
                    .keyPoints
                    .isEmpty {

                    insightCard {

                        keyPointsSection
                    }
                }

                if !currentNote
                    .actionItems
                    .isEmpty {

                    insightCard {

                        actionItemsSection
                    }
                }

                if let summaryError {

                    Text(
                        summaryError
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 11
                        )
                    )
                    .foregroundStyle(
                        .red
                    )
                }
            }

        } else {

            generateSummaryCard
        }
    }

    private func insightCard<
        Content: View
    >(
        @ViewBuilder content:
            () -> Content
    ) -> some View {

        content()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding(16)
            .background(
                RoundedRectangle(
                    cornerRadius: 15,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface.opacity(
                        0.62
                    )
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 15,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            )
    }

    private var hasGeneratedSummary:
        Bool {

        guard let summary =
            currentNote
                .summary?
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
        else {
            return false
        }

        return !summary.isEmpty
    }

    private var generateSummaryCard:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(
                alignment: .top,
                spacing: 12
            ) {

                Image(
                    systemName:
                        "sparkles"
                )
                .font(
                    .system(
                        size: 17,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    Color.purple.opacity(
                        0.8
                    )
                )
                .frame(
                    width: 38,
                    height: 38
                )
                .background(
                    Circle()
                        .fill(
                            Color.purple.opacity(
                                0.08
                            )
                        )
                )

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        "Generate meeting insights"
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 15
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                    Text(
                        "Create a concise summary, key points, and action items from this conversation."
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 11
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                Spacer()
            }

            if let summaryError {

                Text(
                    summaryError
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    .red
                )
            }

            Button {

                generateSummary()

            } label: {

                HStack(
                    spacing: 8
                ) {

                    if isGeneratingSummary {

                        ProgressView()
                            .controlSize(
                                .small
                            )

                    } else {

                        Image(
                            systemName:
                                "sparkles"
                        )

                        Text(
                            "Generate Summary"
                        )
                    }
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    FlowVoiceTheme.accentButtonText
                )
                .padding(
                    .horizontal,
                    14
                )
                .frame(
                    height: 38
                )
                .background(
                    FlowVoiceTheme.accentButton,
                    in:
                        RoundedRectangle(
                            cornerRadius: 10,
                            style:
                                .continuous
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(
                isGeneratingSummary
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        )
    }

    // MARK: - Summary

    private var summarySection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 9
        ) {

            sectionHeader(
                title: "SUMMARY",
                icon: "sparkles"
            )

            Text(
                currentNote.summary ?? ""
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 13
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .lineSpacing(4)
            .textSelection(
                .enabled
            )
        }
    }

    // MARK: - Key Points

    private var keyPointsSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            sectionHeader(
                title: "KEY POINTS",
                icon: "list.bullet"
            )

            VStack(
                alignment: .leading,
                spacing: 9
            ) {

                ForEach(
                    Array(
                        currentNote
                            .keyPoints
                            .enumerated()
                    ),
                    id: \.offset
                ) { _, point in

                    HStack(
                        alignment: .top,
                        spacing: 9
                    ) {

                        Circle()
                            .fill(
                                FlowVoiceTheme.tertiaryText
                            )
                            .frame(
                                width: 4,
                                height: 4
                            )
                            .padding(
                                .top,
                                7
                            )

                        Text(
                            point
                        )
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 12
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                        .lineSpacing(3)
                    }
                }
            }
        }
    }

    // MARK: - Action Items

    private var actionItemsSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            sectionHeader(
                title: "ACTION ITEMS",
                icon:
                    "checkmark.circle"
            )

            VStack(
                alignment: .leading,
                spacing: 9
            ) {

                ForEach(
                    Array(
                        currentNote
                            .actionItems
                            .enumerated()
                    ),
                    id: \.offset
                ) { _, action in

                    HStack(
                        alignment: .top,
                        spacing: 9
                    ) {

                        Image(
                            systemName:
                                "circle"
                        )
                        .font(
                            .system(
                                size: 11,
                                weight:
                                    .regular
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.tertiaryText
                        )
                        .padding(
                            .top,
                            2
                        )

                        Text(
                            action
                        )
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 12
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                        .lineSpacing(3)
                    }
                }
            }
        }
    }

    // MARK: - Transcript

    private var transcriptSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                sectionHeader(
                    title:
                        "FULL TRANSCRIPT",
                    icon:
                        "text.alignleft"
                )

                Spacer()

                if !currentNote
                    .segments
                    .isEmpty {

                    HStack(
                        spacing: 5
                    ) {

                        Image(
                            systemName:
                                "person.2.fill"
                        )

                        Text(
                            "DIARIZED"
                        )
                    }
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 8
                        )
                        .weight(.semibold)
                    )
                    .tracking(1)
                    .foregroundStyle(
                        Color.purple.opacity(
                            0.65
                        )
                    )
                }
            }

            if currentNote
                .segments
                .isEmpty {

                plainTranscript

            } else {

                diarizedTranscript
            }
        }
    }

    // MARK: - Old Note Fallback

    private var plainTranscript:
        some View {

        Text(
            currentNote.transcript
        )
        .font(
            .custom(
                "Avenir Next",
                size: 13
            )
        )
        .foregroundStyle(
            FlowVoiceTheme.primaryText
        )
        .lineSpacing(5)
        .frame(
            maxWidth: .infinity,
            alignment: .topLeading
        )
        .textSelection(
            .enabled
        )
    }

    // MARK: - Diarized Transcript

    private var diarizedTranscript:
        some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            ForEach(
                currentNote.segments
            ) { segment in

                savedSpeakerRow(
                    segment
                )
            }
        }
    }

    // MARK: - Saved Speaker Row

    private func savedSpeakerRow(
        _ segment:
            NoteSpeakerSegment
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            ZStack {

                Circle()
                    .fill(
                        speakerColor(
                            segment.speaker
                        )
                        .opacity(
                            0.12
                        )
                    )
                    .frame(
                        width: 32,
                        height: 32
                    )

                Text(
                    "\(segment.speaker + 1)"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    speakerColor(
                        segment.speaker
                    )
                )
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                HStack(
                    spacing: 8
                ) {

                    Text(
                        "Speaker \(segment.speaker + 1)"
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 10
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        speakerColor(
                            segment.speaker
                        )
                    )

                    if let start =
                        segment.start {

                        Text(
                            formattedTimestamp(
                                start
                            )
                        )
                        .font(
                            .system(
                                size: 9,
                                weight:
                                    .regular,
                                design:
                                    .monospaced
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.mutedText
                        )
                    }
                }

                Text(
                    segment.text
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 13
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
                .lineSpacing(5)
                .textSelection(
                    .enabled
                )
            }

            Spacer(
                minLength: 0
            )
        }
        .padding(
            .vertical,
            4
        )
    }

    // MARK: - Speaker Color

    private func speakerColor(
        _ speaker: Int
    ) -> Color {

        switch speaker % 6 {

        case 0:
            return .blue

        case 1:
            return .orange

        case 2:
            return .green

        case 3:
            return .purple

        case 4:
            return .pink

        default:
            return .teal
        }
    }

    // MARK: - Timestamp

    private func formattedTimestamp(
        _ seconds: Double
    ) -> String {

        let totalSeconds =
            max(
                0,
                Int(seconds)
            )

        let minutes =
            totalSeconds / 60

        let remainingSeconds =
            totalSeconds % 60

        return String(
            format:
                "%d:%02d",
            minutes,
            remainingSeconds
        )
    }

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        icon: String
    ) -> some View {

        HStack(
            spacing: 7
        ) {

            Image(
                systemName:
                    icon
            )
            .font(
                .system(
                    size: 11,
                    weight: .medium
                )
            )

            Text(
                title
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 9
                )
                .weight(.semibold)
            )
            .tracking(1.5)
        }
        .foregroundStyle(
            FlowVoiceTheme.mutedText
        )
    }

    // MARK: - Bottom Bar

    private var bottomBar:
        some View {

        HStack {

            if !currentNote
                .segments
                .isEmpty {

                Text(
                    "\(currentNote.segments.count) transcript segments"
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 10
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.mutedText
                )
            }

            Spacer()

            Button {

                copyTranscript()

            } label: {

                HStack(
                    spacing: 7
                ) {

                    Image(
                        systemName:
                            didCopy
                            ? "checkmark"
                            : "doc.on.doc"
                    )

                    Text(
                        didCopy
                        ? "Copied"
                        : "Copy transcript"
                    )
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    FlowVoiceTheme.accentButtonText
                )
                .padding(
                    .horizontal,
                    14
                )
                .frame(
                    height: 38
                )
                .background(
                    FlowVoiceTheme.accentButton,
                    in:
                        RoundedRectangle(
                            cornerRadius: 10,
                            style:
                                .continuous
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Generate Summary

    private func generateSummary() {

        guard
            !isGeneratingSummary
        else {
            return
        }

        isGeneratingSummary =
            true

        summaryError =
            nil

        Task {

            do {

                let summarizedNote =
                    try await NoteService
                        .shared
                        .summarizeNote(
                            id:
                                currentNote.id
                        )

                withAnimation(
                    .easeInOut(
                        duration: 0.2
                    )
                ) {

                    currentNote =
                        summarizedNote
                }

                // Keep NotetakerView's
                // notes array synchronized.
                onNoteUpdated(
                    summarizedNote
                )

                print(
                    "Summary generated for note:",
                    currentNote.id
                )

            } catch {

                summaryError =
                    "Could not generate summary."

                print(
                    "Could not generate summary:",
                    error
                )
            }

            isGeneratingSummary =
                false
        }
    }

    // MARK: - Copy

    private func copyTranscript() {

        let pasteboard =
            NSPasteboard.general

        pasteboard.clearContents()

        let textToCopy:
            String

        if currentNote
            .segments
            .isEmpty {

            textToCopy =
                currentNote.transcript

        } else {

            textToCopy =
                currentNote
                    .segments
                    .map { segment in

                        let timestamp:
                            String

                        if let start =
                            segment.start {

                            timestamp =
                                " [\(formattedTimestamp(start))]"

                        } else {

                            timestamp =
                                ""
                        }

                        return """
                        Speaker \(segment.speaker + 1)\(timestamp)
                        \(segment.text)
                        """
                    }
                    .joined(
                        separator:
                            "\n\n"
                    )
        }

        pasteboard.setString(
            textToCopy,
            forType: .string
        )

        didCopy =
            true

        DispatchQueue.main
            .asyncAfter(
                deadline:
                    .now() + 1.2
            ) {

                didCopy =
                    false
            }
    }

    // MARK: - Duration

    private func formattedDuration(
        _ seconds: Int
    ) -> String {

        let minutes =
            seconds / 60

        let remainingSeconds =
            seconds % 60

        return String(
            format:
                "%d:%02d",
            minutes,
            remainingSeconds
        )
    }

    // MARK: - Date

    private func formattedDate(
        _ isoDate: String
    ) -> String {

        let formatter =
            ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        guard let date =
            formatter.date(
                from: isoDate
            )
        else {
            return ""
        }

        let output =
            DateFormatter()

        output.dateStyle =
            .medium

        output.timeStyle =
            .short

        return output.string(
            from: date
        )
    }
}

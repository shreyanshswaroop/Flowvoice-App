import SwiftUI

struct NotetakerView: View {

    @EnvironmentObject var controller:
        FlowVoiceController

    @State private var title =
        ""

    @State private var notes:
        [Note] = []

    @State private var isRecording =
        false

    @State private var startedAt:
        Date?

    @State private var isSaving =
        false

    @State private var errorMessage:
        String?

    @State private var selectedNote:
        Note?

    @State private var elapsedSeconds =
        0

    @State private var timerTask:
        Task<Void, Never>?

    private let pageBackground =
        FlowVoiceTheme.pageBackground

    var body: some View {

        ZStack {

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 28
                ) {

                    headerSection

                    recorderCard

                    recentNotesSection
                }
                .padding(
                    .horizontal,
                    34
                )
                .padding(
                    .top,
                    30
                )
                .padding(
                    .bottom,
                    50
                )
            }
            .scrollIndicators(.hidden)
            .background(
                pageBackground
            )

            if let selectedNote {

                NoteDetailView(
                    note:
                        selectedNote,
                    onClose: {

                        withAnimation(
                            .easeInOut(
                                duration:
                                    0.18
                            )
                        ) {

                            self.selectedNote =
                                nil
                        }
                    },
                    onNoteUpdated: {
                        updatedNote in

                        updateNoteLocally(
                            updatedNote
                        )
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .task {

            await loadNotes()
        }
        .onDisappear {

            stopTimer()
        }
    }

    // MARK: - Update Local Note

    private func updateNoteLocally(
        _ updatedNote: Note
    ) {

        if let index =
            notes.firstIndex(
                where: {
                    $0.id ==
                        updatedNote.id
                }
            ) {

            notes[index] =
                updatedNote
        }

        selectedNote =
            updatedNote
    }

    // MARK: - Live Transcript

    private var liveTranscript:
        String {

        let final =
            controller
                .noteTranscript
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let partial =
            controller
                .notePartialTranscript
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        if final.isEmpty {
            return partial
        }

        if partial.isEmpty {
            return final
        }

        return final + " " + partial
    }

    // MARK: - Header

    private var headerSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Notetaker")
                .font(
                    .custom(
                        "Avenir Next",
                        size: 38
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            Text(
                "Capture meetings and conversations without losing the thread."
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 14
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.secondaryText
            )
        }
    }

    // MARK: - Recorder Card

    private var recorderCard:
        some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        isRecording
                        ? "Recording note"
                        : "Start a new note"
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 21
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                    Text(
                        isRecording
                        ? "FlowVoice is listening and identifying speakers."
                        : "Give the note a title and start listening."
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
                }

                Spacer()

                if isRecording {

                    HStack(
                        spacing: 10
                    ) {

                        HStack(
                            spacing: 7
                        ) {

                            Circle()
                                .fill(
                                    Color.red
                                )
                                .frame(
                                    width: 7,
                                    height: 7
                                )

                            Text("LIVE")
                                .font(
                                    .custom(
                                        "Avenir Next",
                                        size: 10
                                    )
                                    .weight(
                                        .semibold
                                    )
                                )
                                .tracking(1.3)
                                .foregroundStyle(
                                    Color.red.opacity(
                                        0.8
                                    )
                                )
                        }

                        Text(
                            formattedDuration(
                                elapsedSeconds
                            )
                        )
                        .font(
                            .system(
                                size: 12,
                                weight:
                                    .medium,
                                design:
                                    .monospaced
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                    }
                }
            }

            TextField(
                "Meeting title",
                text: $title
            )
            .textFieldStyle(.plain)
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 15
                )
            )
            .padding(
                .horizontal,
                14
            )
            .frame(
                height: 44
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 12,
                    style:
                        .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 12,
                    style:
                        .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            )
            .disabled(
                isRecording
            )

            transcriptArea

            if let errorMessage {

                Text(
                    errorMessage
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                )
                .foregroundStyle(
                    .red
                )
            }

            HStack {

                Spacer()

                if isRecording {

                    Button {

                        stopAndSave()

                    } label: {

                        HStack(
                            spacing: 8
                        ) {

                            if isSaving {

                                ProgressView()
                                    .controlSize(
                                        .small
                                    )

                            } else {

                                Image(
                                    systemName:
                                        "stop.fill"
                                )

                                Text(
                                    "Stop & Save"
                                )
                            }
                        }
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 13
                            )
                            .weight(
                                .semibold
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.accentButtonText
                        )
                        .padding(
                            .horizontal,
                            18
                        )
                        .frame(
                            height: 42
                        )
                        .background(
                            FlowVoiceTheme.accentButton,
                            in:
                                RoundedRectangle(
                                    cornerRadius:
                                        12,
                                    style:
                                        .continuous
                                )
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                    .disabled(
                        isSaving
                    )

                } else {

                    Button {

                        startNote()

                    } label: {

                        HStack(
                            spacing: 8
                        ) {

                            Image(
                                systemName:
                                    "record.circle"
                            )

                            Text(
                                "Start Note"
                            )
                        }
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 13
                            )
                            .weight(
                                .semibold
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.accentButtonText
                        )
                        .padding(
                            .horizontal,
                            18
                        )
                        .frame(
                            height: 42
                        )
                        .background(
                            FlowVoiceTheme.accentButton,
                            in:
                                RoundedRectangle(
                                    cornerRadius:
                                        12,
                                    style:
                                        .continuous
                                )
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                    .disabled(
                        title
                            .trimmingCharacters(
                                in:
                                    .whitespacesAndNewlines
                            )
                            .isEmpty
                        ||
                        controller
                            .isListening
                    )
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(
                cornerRadius: 24,
                style:
                    .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 24,
                style:
                    .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        )
        .shadow(
            color:
                .black.opacity(
                    0.035
                ),
            radius: 14,
            x: 0,
            y: 8
        )
    }

    // MARK: - Transcript Area

    private var transcriptArea:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            HStack {

                Text(
                    "LIVE TRANSCRIPT"
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 9
                    )
                    .weight(
                        .semibold
                    )
                )
                .tracking(1.5)
                .foregroundStyle(
                    FlowVoiceTheme.mutedText
                )

                Spacer()

                if isRecording {

                    HStack(
                        spacing: 4
                    ) {

                        Image(
                            systemName:
                                "waveform"
                        )
                        .font(
                            .system(
                                size: 10,
                                weight:
                                    .medium
                            )
                        )

                        Text(
                            "Listening"
                        )
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 9
                            )
                            .weight(
                                .medium
                            )
                        )
                    }
                    .foregroundStyle(
                        FlowVoiceTheme.tertiaryText
                    )
                }
            }

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 16
                ) {

                    if controller
                        .noteSpeakerSegments
                        .isEmpty {

                        fallbackTranscript

                    } else {

                        speakerTranscript
                    }

                    if !controller
                        .notePartialTranscript
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                        .isEmpty {

                        partialTranscriptRow
                    }
                }
                .frame(
                    maxWidth:
                        .infinity,
                    alignment:
                        .leading
                )
            }
            .frame(
                minHeight: 150,
                maxHeight: 260
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style:
                    .continuous
            )
            .fill(
                FlowVoiceTheme.inputSurface.opacity(
                    0.62
                )
            )
        )
    }

    // MARK: - Speaker Transcript

    private var speakerTranscript:
        some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            ForEach(
                controller
                    .noteSpeakerSegments
            ) { segment in

                speakerSegmentRow(
                    segment
                )
            }
        }
    }

    // MARK: - Speaker Row

    private func speakerSegmentRow(
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
                            segment
                                .speaker
                        )
                        .opacity(
                            0.12
                        )
                    )
                    .frame(
                        width: 30,
                        height: 30
                    )

                Text(
                    "\(segment.speaker + 1)"
                )
                .font(
                    .system(
                        size: 11,
                        weight:
                            .semibold
                    )
                )
                .foregroundStyle(
                    speakerColor(
                        segment
                            .speaker
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
                        .weight(
                            .semibold
                        )
                    )
                    .foregroundStyle(
                        speakerColor(
                            segment
                                .speaker
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
                        size: 14
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

            Spacer(
                minLength: 0
            )
        }
    }

    // MARK: - Partial Transcript

    private var partialTranscriptRow:
        some View {

        HStack(
            alignment: .top,
            spacing: 12
        ) {

            ZStack {

                Circle()
                    .fill(
                        FlowVoiceTheme.selectedSurface
                    )
                    .frame(
                        width: 30,
                        height: 30
                    )

                Image(
                    systemName:
                        "waveform"
                )
                .font(
                    .system(
                        size: 11,
                        weight:
                            .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    "Listening..."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 10
                    )
                    .weight(
                        .medium
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )

                Text(
                    controller
                        .notePartialTranscript
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 14
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )
                .lineSpacing(4)
            }

            Spacer(
                minLength: 0
            )
        }
    }

    // MARK: - Fallback Transcript

    private var fallbackTranscript:
        some View {

        Text(
            liveTranscript.isEmpty
            ? "Your transcript will appear here."
            : liveTranscript
        )
        .font(
            .custom(
                "Avenir Next",
                size: 14
            )
        )
        .foregroundStyle(
            liveTranscript.isEmpty
            ? FlowVoiceTheme.tertiaryText
            : FlowVoiceTheme.primaryText
        )
        .lineSpacing(4)
        .frame(
            maxWidth:
                .infinity,
            alignment:
                .topLeading
        )
        .textSelection(
            .enabled
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

    // MARK: - Recent Notes

    private var recentNotesSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {

                    Text(
                        "RECENT NOTES"
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 9
                        )
                        .weight(
                            .semibold
                        )
                    )
                    .tracking(1.6)
                    .foregroundStyle(
                        FlowVoiceTheme.mutedText
                    )

                    Text(
                        "Your notes"
                    )
                    .font(
                        .custom(
                            "GrandHotel",
                            size: 34
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )
                }

                Spacer()
            }

            if notes.isEmpty {

                Text(
                    "No saved notes yet."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 13
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
                .padding(
                    .vertical,
                    24
                )

            } else {

                VStack(
                    spacing: 0
                ) {

                    ForEach(
                        Array(
                            notes.enumerated()
                        ),
                        id:
                            \.element.id
                    ) {
                        index,
                        note in

                        NoteRow(
                            note:
                                note
                        ) {

                            withAnimation(
                                .easeInOut(
                                    duration:
                                        0.18
                                )
                            ) {

                                selectedNote =
                                    note
                            }

                        } onDelete: {

                            deleteNote(
                                note
                            )
                        }

                        if index !=
                            notes.count - 1 {

                            Divider()
                                .overlay(
                                    FlowVoiceTheme.divider
                                )
                                .padding(
                                    .leading,
                                    20
                                )
                        }
                    }
                }
                .background(
                    RoundedRectangle(
                        cornerRadius:
                            22,
                        style:
                            .continuous
                    )
                    .fill(
                        FlowVoiceTheme.surface
                    )
                )
            }
        }
    }

    // MARK: - Start Note

    private func startNote() {

        let cleanedTitle =
            title
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            !cleanedTitle.isEmpty
        else {
            return
        }

        errorMessage =
            nil

        startedAt =
            Date()

        elapsedSeconds =
            0

        isRecording =
            true

        startTimer()

        controller
            .startNotetaker()
    }

    // MARK: - Stop & Save

    private func stopAndSave() {

        guard isRecording else {
            return
        }

        stopTimer()

        controller
            .stopNotetaker()

        isRecording =
            false

        isSaving =
            true

        errorMessage =
            nil

        let duration =
            startedAt.map {

                max(
                    0,
                    Int(
                        Date()
                            .timeIntervalSince(
                                $0
                            )
                    )
                )
            }

        startedAt =
            nil

        Task {

            // Give Deepgram enough time to return
            // the final diarized chunk after Finalize.

            try? await Task.sleep(
                nanoseconds:
                    900_000_000
            )

            let cleanedTranscript =
                controller
                    .noteTranscript
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            guard
                !cleanedTranscript.isEmpty
            else {

                isSaving =
                    false

                errorMessage =
                    "No transcript was captured."

                controller
                    .resetNotetaker()

                return
            }

            let capturedSegments =
                controller
                    .noteSpeakerSegments

            do {

                let saved =
                    try await NoteService
                        .shared
                        .createNote(
                            title:
                                title
                                .trimmingCharacters(
                                    in:
                                        .whitespacesAndNewlines
                                ),
                            transcript:
                                cleanedTranscript,
                            durationSeconds:
                                duration,
                            segments:
                                capturedSegments
                        )

                notes.insert(
                    saved,
                    at: 0
                )

                title =
                    ""

                controller
                    .resetNotetaker()

                print(
                    "Note saved:",
                    saved.id
                )

                print(
                    "Saved speaker segments:",
                    capturedSegments.count
                )

            } catch {

                errorMessage =
                    "Could not save note."

                print(
                    "Could not save note:",
                    error
                )
            }

            isSaving =
                false
        }
    }

    // MARK: - Timer

    private func startTimer() {

        timerTask?.cancel()

        elapsedSeconds =
            0

        timerTask =
            Task {

                while
                    !Task.isCancelled {

                    try? await Task.sleep(
                        nanoseconds:
                            1_000_000_000
                    )

                    if Task.isCancelled {
                        return
                    }

                    await MainActor.run {

                        elapsedSeconds +=
                            1
                    }
                }
            }
    }

    private func stopTimer() {

        timerTask?.cancel()

        timerTask =
            nil
    }

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

    // MARK: - Load Notes

    private func loadNotes()
        async {

        do {

            notes =
                try await NoteService
                    .shared
                    .fetchNotes()

        } catch {

            print(
                "Could not load notes:",
                error
            )
        }
    }

    // MARK: - Delete Note

    private func deleteNote(
        _ note: Note
    ) {

        Task {

            do {

                try await NoteService
                    .shared
                    .deleteNote(
                        id:
                            note.id
                    )

                withAnimation(
                    .easeInOut(
                        duration:
                            0.2
                    )
                ) {

                    notes.removeAll {
                        $0.id ==
                            note.id
                    }
                }

                if selectedNote?.id ==
                    note.id {

                    selectedNote =
                        nil
                }

            } catch {

                print(
                    "Could not delete note:",
                    error
                )
            }
        }
    }
}

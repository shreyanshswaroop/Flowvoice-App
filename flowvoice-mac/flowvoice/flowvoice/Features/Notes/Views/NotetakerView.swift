import SwiftUI

private struct PendingNoteDraft {

    let title: String
    let transcript: String
    let durationSeconds: Int?
    let segments: [NoteSpeakerSegment]
    let thoughts: String

    var transcriptWordCount: Int {

        transcript
            .split(separator: " ")
            .count
    }
}

struct NotetakerView: View {

    @State private var noteSearch = ""
    @State private var showingNoteSearch = false
    @FocusState private var noteSearchFocused: Bool
    @State private var menuNote: Note?
    @State private var hoveredNoteID: String?
    @State private var finishButtonContracted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

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

    @State private var isFinalizing =
        false

    @State private var errorMessage:
        String?

    @State private var selectedNote:
        Note?

    @State private var elapsedSeconds =
        0

    @State private var timerTask:
        Task<Void, Never>?

    @State private var showingLiveNote = false
    @State private var liveThoughts = ""
    @State private var transcriptCollapsed = false
    @State private var liveSearchVisible = false
    @State private var liveSearch = ""

    @State private var pendingNoteDraft:
        PendingNoteDraft?

    @State private var showKeepPrompt =
        false

    private let pageBackground =
        FlowVoiceTheme.pageBackground

    var body: some View {

        ZStack {

            if showingLiveNote {
                liveNotePage
            } else {
            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 42
                ) {

                    topActionBar

                    upcomingSection

                    if let errorMessage {
                        HStack(spacing: 10) {
                            Label(errorMessage, systemImage: "exclamationmark.circle")
                                .font(.system(size: 13))
                                .foregroundStyle(FlowVoiceTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 8)
                            Button {
                                self.errorMessage = nil
                            } label: {
                                Image(systemName: "xmark")
                                    .frame(width: 28, height: 28)
                            }
                            .buttonStyle(.plain)
                            .help("Dismiss message")
                            .accessibilityLabel("Dismiss message")
                        }
                    }

                    recentNotesSection
                }
                .frame(
                    maxWidth: 940,
                    alignment: .leading
                )
                .padding(
                    .horizontal,
                    58
                )
                .padding(.top, 18)
                .padding(
                    .bottom,
                    58
                )
            }
            .scrollIndicators(.hidden)
            .background(
                pageBackground
            )
            }

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
                    },
                    onNoteDeleted: { deletedNote in
                        notes.removeAll { $0.id == deletedNote.id }
                    }
                )
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .overlayPreferenceValue(NoteMenuAnchorKey.self) { anchor in
            if let menuNote, let anchor {
                GeometryReader { geometry in
                    let button = geometry[anchor]
                    let width = min(220, geometry.size.width - 32)
                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { self.menuNote = nil }
                        recentNoteMenu(menuNote)
                            .frame(width: width)
                            .offset(
                                x: max(16, button.maxX - width),
                                y: button.maxY + 100 < geometry.size.height
                                    ? button.maxY + 6 : max(8, button.minY - 100)
                            )
                    }
                }
            }
        }
        .onExitCommand {
            menuNote = nil
            showKeepPrompt = false
        }
        .task {

            await loadNotes()
        }
        .onDisappear {

            stopTimer()

            if isRecording {
                finishNoteForReview()
            }
        }
        .allowsHitTesting(!showKeepPrompt)
        .overlay(alignment: .bottom) {
            if showKeepPrompt, let draft = pendingNoteDraft {
                KeepNotePrompt(
                    wordCount: draft.transcriptWordCount,
                    onClose: { showKeepPrompt = false },
                    onDiscard: { discardPendingNote() },
                    onKeep: {
                        showKeepPrompt = false
                        savePendingNote(draft)
                    }
                )
                .frame(maxWidth: 420)
                .transition(reduceMotion ? .opacity : .scale(scale: 0.12, anchor: .bottom).combined(with: .opacity))
                .padding(20)
            }
        }
        .animation(
            reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.8),
            value: showKeepPrompt
        )
        .onChange(of: showKeepPrompt) { _, isPresented in
            if !isPresented { finishButtonContracted = false }
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

    // MARK: - Top Action Bar

    private var topActionBar:
        some View {

        HStack {

            Spacer()

            Button {

                startNewNote()

            } label: {

                HStack(spacing: 8) {

                    Image(systemName: "plus")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )

                    Text("New note")
                }
                .font(
                    .system(
                        size: 15,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
                .padding(
                    .horizontal,
                    16
                )
                .frame(height: 36)
                .background(
                    Capsule()
                        .fill(
                            FlowVoiceTheme.elevatedSurface
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            FlowVoiceTheme.hairline,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(NoteActionButtonStyle(cornerRadius: 100))
            .disabled(
                isRecording ||
                controller.isListening ||
                isFinalizing
            )
        }
    }

    // MARK: - Upcoming

    private var upcomingSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            Text("Coming up")
                .font(
                    .system(
                        size: 30,
                        weight: .regular,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            HStack(
                alignment: .top,
                spacing: 28
            ) {

                calendarDateBlock

                VStack(spacing: 14) {
                    demoMeetingCard
                    emptyCalendarCard
                }
            }
            .padding(
                EdgeInsets(
                    top: 18,
                    leading: 24,
                    bottom: 18,
                    trailing: 18
                )
            )
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FlowVoiceTheme.surface)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(
                    cornerRadius: 18,
                    style: .continuous
                )
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
            )
        }
    }

    private var calendarDateBlock:
        some View {

        HStack(
            alignment: .top,
            spacing: 18
        ) {

            Text(currentDayNumber)
                .font(
                    .system(
                        size: 32,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
                .monospacedDigit()

            VStack(
                alignment: .leading,
                spacing: 2
            ) {

                HStack(spacing: 5) {

                    Text(currentMonthName)
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )

                    Circle()
                        .fill(Color.red.opacity(0.78))
                        .frame(
                            width: 5,
                            height: 5
                        )
                }
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

                Text(currentWeekdayName)
                    .font(
                        .system(
                            size: 14,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )
            }
            .padding(.top, 7)
        }
        .frame(
            width: 180,
            alignment: .leading
        )
    }

    private var demoMeetingCard:
        some View {

        HStack(spacing: 14) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
                .fill(
                    LinearGradient(
                        colors: [
                            FlowVoiceTheme.secondaryText,
                            FlowVoiceTheme.accentButton
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

                Image(systemName: "play.fill")
                    .font(
                        .system(
                            size: 16,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 30,
                        height: 30
                    )
                    .background(
                        Circle()
                            .fill(.black.opacity(0.22))
                    )
            }
            .frame(
                width: 58,
                height: 58
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8,
                    style: .continuous
                )
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text("Try a demo meeting")
                    .font(
                        .system(
                            size: 17,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Text("Learn how to use FlowVoice in 2 minutes")
                    .font(
                        .system(
                            size: 15,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )
            }

            Spacer()

            Button {

                startNewNote()

            } label: {

                Text("Start now")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.accentButtonText
                    )
                    .padding(
                        .horizontal,
                        16
                    )
                    .frame(height: 36)
                    .background(
                        Capsule()
                            .fill(
                                FlowVoiceTheme.accentButton
                            )
                    )
            }
            .buttonStyle(NoteActionButtonStyle(prominent: true, cornerRadius: 100))
            .disabled(
                isRecording ||
                controller.isListening ||
                isFinalizing
            )
        }
        .padding(
            .horizontal,
            12
        )
        .frame(height: 76)
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.selectedSurface
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

    private var emptyCalendarCard:
        some View {

        VStack(spacing: 18) {

            Image(systemName: "calendar.badge.clock")
                .font(
                    .system(
                        size: 29,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )

            Text("No upcoming events")
                .font(
                    .system(
                        size: 18,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 220
        )
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.inputSurface.opacity(0.42)
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                style:
                    StrokeStyle(
                        lineWidth: 1,
                        dash: [6, 6]
                    )
            )
        )
    }

    private var statusPill:
        some View {

        HStack(spacing: 8) {

            Circle()
                .fill(
                    isRecording
                    ? Color.red
                    : FlowVoiceTheme.secondaryText
                )
                .frame(
                    width: 7,
                    height: 7
                )

            Text(
                isRecording
                ? "Live"
                : "Ready"
            )
            .font(
                .system(
                    size: 13,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            7
        )
        .background {

            Capsule()
                .fill(
                    FlowVoiceTheme.elevatedSurface
                )
        }
        .overlay {

            Capsule()
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
        }
    }

    private func metricPill(
        value: String,
        label: String,
        tint: Color
    ) -> some View {

        HStack(spacing: 8) {

            Circle()
                .fill(tint)
                .frame(
                    width: 7,
                    height: 7
                )

            Text(value)
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )

            Text(label)
                .font(
                    .system(
                        size: 13,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
        }
        .padding(
            .horizontal,
            12
        )
        .padding(
            .vertical,
            7
        )
        .background {

            Capsule()
                .fill(
                    FlowVoiceTheme.elevatedSurface
                )
        }
        .overlay {

            Capsule()
                .stroke(
                    FlowVoiceTheme.hairline,
                    lineWidth: 1
                )
        }
    }

    // MARK: - Recorder Card

    private var recorderCard:
        some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        isRecording
                        ? "Listening"
                        : "Start a new note"
                    )
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
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
                        .system(
                            size: 13,
                            weight: .regular
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
                                    .system(
                                        size: 10,
                                        weight:
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
                .system(
                    size: 14,
                    weight: .regular
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
                    cornerRadius: 8,
                    style:
                        .continuous
                )
                .fill(
                    FlowVoiceTheme.inputSurface
                )
            )
            .overlay(
                RoundedRectangle(
                    cornerRadius: 8,
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

                        finishNoteForReview()

                    } label: {

                        HStack(
                            spacing: 8
                        ) {

                            if isFinalizing {

                                ProgressView()
                                    .controlSize(
                                        .small
                                    )

                            } else {

                                Image(
                                    systemName:
                                        "checkmark"
                                )

                                Text(
                                    "Finish Note"
                                )
                            }
                        }
                        .font(
                            .system(
                                size: 13,
                                weight:
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
                                        8,
                                    style:
                                        .continuous
                                )
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                    .disabled(
                        isFinalizing
                    )

                } else {

                    Button {

                        startNewNote()

                    } label: {

                        HStack(
                            spacing: 8
                        ) {

                            Image(
                                systemName:
                                    "record.circle"
                            )

                            Text(
                                "New note"
                            )
                        }
                        .font(
                            .system(
                                size: 13,
                                weight:
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
                                        8,
                                    style:
                                        .continuous
                                )
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
                    .disabled(
                        controller
                            .isListening
                        ||
                        isFinalizing
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(
                cornerRadius: 8,
                style:
                    .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 8,
                style:
                    .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        )
    }

    // MARK: - Transcript Area

    private var transcriptArea:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text(
                    "LIVE TRANSCRIPT"
                )
                .font(
                    .system(
                        size: 10,
                        weight:
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
                            .system(
                                size: 10,
                                weight:
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
                minHeight: 142,
                maxHeight: 238
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(
                cornerRadius: 8,
                style:
                    .continuous
            )
            .fill(
                FlowVoiceTheme.inputSurface.opacity(
                    0.48
                )
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 8,
                style:
                    .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
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
            return FlowVoiceTheme.secondaryText

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

    private var recentNotesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button {
                    showingNoteSearch.toggle()
                    noteSearchFocused = showingNoteSearch
                    if !showingNoteSearch { noteSearch = "" }
                } label: {
                    Image(systemName: showingNoteSearch ? "xmark" : "magnifyingglass")
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(NoteActionButtonStyle())
                .help(showingNoteSearch ? "Close search" : "Search notes")
                .accessibilityLabel(showingNoteSearch ? "Close search" : "Search notes")
            }
            if showingNoteSearch {
                TextField("Search notes", text: $noteSearch)
                    .textFieldStyle(.roundedBorder)
                    .focused($noteSearchFocused)
            }
            if groupedNotes.isEmpty {
                Label(notes.isEmpty ? "No notes yet" : "No matching notes", systemImage: "doc.text")
                    .font(.system(size: 14))
                    .foregroundStyle(FlowVoiceTheme.tertiaryText)
                    .frame(maxWidth: .infinity, minHeight: 110)
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(groupedNotes, id: \.title) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(group.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FlowVoiceTheme.secondaryText)
                            ForEach(group.notes) { note in
                                homeNoteRow(note)
                            }
                        }
                    }
                }
            }
        }
    }

    private func homeNoteRow(
        _ note: Note
    ) -> some View {

        HStack(spacing: 18) {
        Button {

            withAnimation(
                .easeInOut(
                    duration:
                        0.18
                )
            ) {

                selectedNote =
                    note
            }

        } label: {

            HStack(spacing: 18) {

                Image(systemName: "doc")
                    .font(
                        .system(
                            size: 17,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.secondaryText
                    )
                    .frame(
                        width: 38,
                        height: 38
                    )
                    .background(
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                        .fill(
                            FlowVoiceTheme.selectedSurface
                        )
                    )
                    .overlay(
                        RoundedRectangle(
                            cornerRadius: 8,
                            style: .continuous
                        )
                        .stroke(
                            FlowVoiceTheme.hairline,
                            lineWidth: 1
                        )
                    )

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(note.title.isEmpty ? "New note" : note.title)
                        .font(
                            .system(
                                size: 17,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.primaryText
                        )

                    Text("Me")
                        .font(
                            .system(
                                size: 15,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.secondaryText
                        )
                }

                Spacer()

                Text(noteTime(note))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FlowVoiceTheme.tertiaryText)
                    .frame(width: 78, alignment: .leading)

            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

                Button {
                    menuNote = note
                } label: {

                    Image(systemName: "ellipsis")
                        .foregroundStyle(
                            FlowVoiceTheme.tertiaryText
                        )
                        .frame(
                            width: 36,
                            height: 36
                        )
                        .contentShape(Rectangle())
                }
                .anchorPreference(key: NoteMenuAnchorKey.self, value: .bounds) {
                    menuNote?.id == note.id ? $0 : nil
                }
                .help("Note actions")
                .accessibilityLabel("Actions for \(note.title)")
        }
        .padding(.vertical, 4)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(hoveredNoteID == note.id ? FlowVoiceTheme.hoverSurface : .clear)
                .padding(.horizontal, -10)
                .padding(.vertical, -4)
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onHover { isHovered in
            if isHovered {
                hoveredNoteID = note.id
            } else if hoveredNoteID == note.id {
                hoveredNoteID = nil
            }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.12), value: hoveredNoteID == note.id)
        .buttonStyle(.plain)
    }

    private func recentNoteMenu(_ note: Note) -> some View {
        VStack(spacing: 0) {
            Button {
                menuNote = nil
                selectedNote = note
            } label: {
                recentMenuLabel("Open", icon: "doc.text.magnifyingglass", color: FlowVoiceTheme.primaryText)
            }
            Rectangle()
                .fill(FlowVoiceTheme.hairline)
                .frame(height: 1)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
            Button(role: .destructive) {
                menuNote = nil
                deleteNote(note)
            } label: {
                recentMenuLabel("Delete", icon: "trash", color: Color(red: 0.82, green: 0.24, blue: 0.13))
            }
        }
        .buttonStyle(NoteMenuButtonStyle())
        .padding(6)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : .white,
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(FlowVoiceTheme.hairline, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
    }

    private func recentMenuLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 16)
            Text(title).font(.system(size: 13))
            Spacer(minLength: 0)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .frame(height: 30)
        .contentShape(Rectangle())
    }

    private var groupedNotes:
        [(title: String, notes: [Note])] {

        var groups:
            [(title: String, notes: [Note])] = []

        let filteredNotes = notes.filter {
            noteSearch.isEmpty || $0.title.localizedStandardContains(noteSearch)
                || $0.transcript.localizedStandardContains(noteSearch)
        }
        let sortedNotes = filteredNotes.map { (note: $0, date: parsedDate($0.createdAt)) }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }

        for entry in sortedNotes {
            let note = entry.note

            let title =
                noteDateGroupTitle(
                    note
                )

            if let index =
                groups.firstIndex(
                    where: {
                        $0.title ==
                            title
                    }
                ) {

                groups[index]
                    .notes
                    .append(
                        note
                    )

            } else {

                groups.append(
                    (
                        title:
                            title,
                        notes:
                            [note]
                    )
                )
            }
        }

        return groups
    }

    private var currentDayNumber:
        String {

        Date()
            .formatted(
                .dateTime.day()
            )
    }

    private var currentMonthName:
        String {

        Date()
            .formatted(
                .dateTime.month(.wide)
            )
    }

    private var currentWeekdayName:
        String {

        Date()
            .formatted(
                .dateTime.weekday(.abbreviated)
            )
    }

    private func noteTime(
        _ note: Note
    ) -> String {

        guard let date =
            parsedDate(
                note.createdAt
            )
        else {
            return ""
        }

        return date.formatted(date: .omitted, time: .shortened)
    }

    private func noteDateGroupTitle(
        _ note: Note
    ) -> String {

        guard let date =
            parsedDate(
                note.createdAt
            )
        else {
            return "Earlier"
        }

        return HistoryDateFormat.day(date)
    }

    private func parsedDate(
        _ value: String
    ) -> Date? {

        let fractionalFormatter =
            ISO8601DateFormatter()

        fractionalFormatter.formatOptions =
            [
                .withInternetDateTime,
                .withFractionalSeconds
            ]

        if let date =
            fractionalFormatter.date(
                from:
                    value
            ) {

            return date
        }

        return ISO8601DateFormatter()
            .date(
                from:
                    value
            )
    }

    // MARK: - New Note

    private func startNewNote() {

        if title
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .isEmpty {

            title =
                "New note"
        }

        startNote()
    }

    // MARK: - Start Note

    private func startNote() {

        guard !isRecording && !isFinalizing && pendingNoteDraft == nil else { return }

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

        liveThoughts = ""
        transcriptCollapsed = false
        liveSearchVisible = false
        liveSearch = ""
        showingLiveNote = true
        menuNote = nil
    }

    // MARK: - Finish For Review

    private func finishNoteForReview() {

        guard isRecording,
              !isFinalizing
        else {
            return
        }

        stopTimer()

        controller
            .stopNotetaker()

        isRecording =
            false

        isFinalizing =
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

            let capturedSegments =
                controller
                    .noteSpeakerSegments

            pendingNoteDraft =
                PendingNoteDraft(
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
                        capturedSegments,
                    thoughts: liveThoughts
                )

            if !reduceMotion {
                withAnimation(.easeIn(duration: 0.18)) {
                    finishButtonContracted = true
                }
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
            isFinalizing = false
            showKeepPrompt = true
        }
    }

    // MARK: - Save Draft

    private func savePendingNote(
        _ draft: PendingNoteDraft
    ) {

        let cleanedTranscript =
            draft.transcript
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard !cleanedTranscript.isEmpty else {

            discardPendingNote()

            errorMessage =
                "No transcript was captured."

            return
        }

        isSaving =
            true

        isFinalizing =
            true

        Task {

            do {

                let saved =
                    try await NoteService
                        .shared
                        .createNote(
                            title:
                                draft.title,
                            transcript:
                                cleanedTranscript,
                            durationSeconds:
                                draft.durationSeconds,
                            segments:
                                draft.segments
                        )

                notes.insert(
                    saved,
                    at: 0
                )

                UserDefaults.standard.set(draft.thoughts, forKey: "noteThoughts.\(saved.id)")

                finishPendingNoteCleanup()
                selectedNote = saved

                print(
                    "Note saved:",
                    saved.id
                )

                print(
                    "Saved speaker segments:",
                    draft.segments.count
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

            isFinalizing =
                false
        }
    }

    // MARK: - Discard Draft

    private func discardPendingNote() {

        finishPendingNoteCleanup()
    }

    private func finishPendingNoteCleanup() {

        errorMessage = nil

        title =
            ""

        pendingNoteDraft =
            nil

        showKeepPrompt =
            false

        isFinalizing =
            false

        controller
            .resetNotetaker()

        showingLiveNote = false
        liveThoughts = ""
    }

    // MARK: - Live Note Page

    private var liveNotePage: some View {
        VStack(spacing: 0) {
            HStack {
                Button {
                    if isRecording { finishNoteForReview() }
                    else { showKeepPrompt = true }
                } label: {
                    Image(systemName: "chevron.left").frame(width: 36, height: 36)
                }
                .help("Finish and review note")
                .disabled(isFinalizing)
                Spacer()
                ShareLink(item: "\(title)\n\n\(liveThoughts)\n\n\(controller.noteTranscript)") {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .padding(.horizontal, 14)
                        .frame(height: 34)
                        .background(FlowVoiceTheme.selectedSurface, in: RoundedRectangle(cornerRadius: 8))
                }
            }
            .buttonStyle(NoteActionButtonStyle())
            .padding(.horizontal, 28)
            .padding(.vertical, 16)

            GeometryReader { geometry in
                let transcriptHeight = min(240, max(80,
                    geometry.size.height - 216 - (liveSearchVisible ? 40 : 0)))
                ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("New note", text: $title)
                        .textFieldStyle(.plain)
                        .font(.system(size: 36, weight: .regular, design: .serif))
                        .disabled(!isRecording)

                    HStack(spacing: 20) {
                        Label("My notes", systemImage: "text.alignleft")
                        Label((startedAt ?? Date()).formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        Label("Me", systemImage: "person")
                    }
                    .font(.system(size: 13))
                    .foregroundStyle(FlowVoiceTheme.secondaryText)

                    Spacer(minLength: 0)

                    VStack(spacing: 0) {
                        HStack {
                            Button {
                                liveSearchVisible.toggle()
                                if !liveSearchVisible { liveSearch = "" }
                            } label: {
                                Image(systemName: "magnifyingglass").frame(width: 30, height: 30)
                            }
                            .help("Search transcript")
                            .accessibilityLabel("Search transcript")
                            Spacer()
                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(controller.noteTranscript, forType: .string)
                            } label: {
                                Image(systemName: "doc.on.doc").frame(width: 30, height: 30)
                            }
                            .help("Copy transcript")
                            Button { transcriptCollapsed.toggle() } label: {
                                Image(systemName: transcriptCollapsed ? "plus" : "minus")
                                    .frame(width: 30, height: 30)
                            }
                            .help(transcriptCollapsed ? "Expand transcript" : "Collapse transcript")
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(FlowVoiceTheme.secondaryText)
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                        if liveSearchVisible {
                            TextField("Search transcript", text: $liveSearch)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 12)
                        }

                        if !transcriptCollapsed {
                            ScrollView {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("Always get consent when transcribing others.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(FlowVoiceTheme.secondaryText)
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.bottom, 20)

                                    if controller.noteSpeakerSegments.isEmpty {
                                        if !controller.noteTranscript.isEmpty && liveMatchesSearch(controller.noteTranscript) {
                                            liveTranscriptBubble(controller.noteTranscript)
                                        }
                                    } else {
                                        ForEach(controller.noteSpeakerSegments.filter { liveMatchesSearch($0.text) }) { segment in
                                            VStack(alignment: .trailing, spacing: 4) {
                                                Text("Speaker \(segment.speaker + 1)")
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(FlowVoiceTheme.tertiaryText)
                                                liveTranscriptBubble(segment.text)
                                            }
                                        }
                                    }
                                    if !controller.notePartialTranscript.isEmpty && liveMatchesSearch(controller.notePartialTranscript) {
                                        liveTranscriptBubble(controller.notePartialTranscript)
                                            .opacity(0.65)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 16)
                            }
                            .frame(height: transcriptHeight)
                        }

                        Divider()
                        HStack(spacing: 10) {
                            Image(systemName: "waveform")
                                .font(.system(size: 22))
                                .foregroundStyle(FlowVoiceTheme.secondaryText)
                            Text(isRecording ? "Recording" : (isFinalizing ? "Finishing..." : "Ready to save"))
                                .foregroundStyle(FlowVoiceTheme.primaryText)
                            Spacer()
                            Text(String(format: "%d:%02d", elapsedSeconds / 60, elapsedSeconds % 60))
                                .monospacedDigit()
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(FlowVoiceTheme.secondaryText)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(NoteActionButtonStyle())
                    .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : .white,
                                in: RoundedRectangle(cornerRadius: 24))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24).strokeBorder(FlowVoiceTheme.hairline, lineWidth: 1)
                            .allowsHitTesting(false)
                    }
                    .shadow(color: .black.opacity(0.035), radius: 6, x: 0, y: 3)
                }
                .frame(maxWidth: 720)
                .frame(minHeight: max(0, geometry.size.height - 16), alignment: .top)
                .padding(.horizontal, 32)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity)
                }
            }

            VStack(spacing: 10) {
                if let errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.system(size: 12))
                }
                if showKeepPrompt {
                    Color.clear.frame(height: 42)
                        .accessibilityHidden(true)
                } else {
                Button {
                    if isRecording { finishNoteForReview() }
                    else if let draft = pendingNoteDraft { savePendingNote(draft) }
                } label: {
                    HStack(spacing: 8) {
                        if isFinalizing { ProgressView().controlSize(.small) }
                        else { Image(systemName: "checkmark") }
                        Text(isFinalizing ? "Finishing..." : (isRecording ? "Finish note" : "Save note"))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, 24)
                    .frame(height: 42)
                    .foregroundStyle(FlowVoiceTheme.accentButtonText)
                    .background(FlowVoiceTheme.accentButton, in: Capsule())
                }
                .scaleEffect(finishButtonContracted ? 0.15 : 1, anchor: .bottom)
                .opacity(finishButtonContracted ? 0.25 : 1)
                .transition(.opacity)
                .buttonStyle(NoteActionButtonStyle(prominent: true, cornerRadius: 100))
                .disabled(isFinalizing)
                }
            }
            .padding(.bottom, 20)
        }
        .foregroundStyle(FlowVoiceTheme.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(pageBackground)
    }

    private func liveMatchesSearch(_ text: String) -> Bool {
        liveSearch.isEmpty || text.localizedStandardContains(liveSearch)
    }

    private func liveTranscriptBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .lineSpacing(4)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .foregroundStyle(FlowVoiceTheme.primaryText)
            .background(FlowVoiceTheme.selectedSurface,
                        in: RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity, alignment: .trailing)
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

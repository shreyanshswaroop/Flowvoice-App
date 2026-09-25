import Foundation
import Combine

@MainActor
enum FlowVoiceState {
    case ready
    case listening
    case transcribing
    case inserted
}

enum FlowVoiceMode {
    case dictation
    case notetaker
}

@MainActor
final class FlowVoiceController: ObservableObject {

    let socket = FlowVoiceSocket()

    // Normal dictation:
    // microphone only.
    private let audioCapture =
        AudioCaptureService()

    // Notetaker:
    // microphone + system/meeting audio.
    private let meetingAudioCapture =
        MeetingAudioCaptureService()

    private var shouldInsertOnFinal =
        false

    private var pendingFinalUtterance =
        ""

    private var isProcessingInsertion =
        false

    private var dictationStartedAt:
        Date?

    @Published var isConnected =
        false

    @Published var statusText =
        "Disconnected"

    @Published var isListening =
        false

    @Published var microphoneError:
        String?

    @Published var state:
        FlowVoiceState = .ready

    @Published var mode:
        FlowVoiceMode = .dictation

    // MARK: - Notetaker

    @Published var noteTranscript =
        ""

    @Published var notePartialTranscript =
        ""

    @Published var notePartialSpeaker: Int?

    @Published var noteSpeakerSegments:
        [NoteSpeakerSegment] = []

    private var noteSpeakerSegmentArchive:
        [NoteSpeakerSegment] = []

    private var noteFinalTranscriptFallbackSegments:
        [String] = []

    private var noteFinalTranscriptFallbackKeys =
        Set<String>()

    // MARK: - Dictation

    @Published var displayTranscript =
        "Hold ⌥ Space to speak"

    @Published var audioLevel:
        Double = 0

    @Published var lastDictationDurationSeconds:
        Int?

    private var cancellables =
        Set<AnyCancellable>()

    init() {

        configureSocketObservers()
        configureDictationAudio()
        configureMeetingAudio()
    }

    // MARK: ============================================
    // MARK: SETUP
    // MARK: ============================================

    private func configureSocketObservers() {

        // MARK: Connection

        socket.$isConnected
            .receive(on: RunLoop.main)
            .assign(
                to: &$isConnected
            )

        socket.$statusText
            .receive(on: RunLoop.main)
            .assign(
                to: &$statusText
            )

        // MARK: Final Utterance

        socket.$finalUtterance
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] text in

                guard let self else {
                    return
                }

                let cleaned =
                    text.trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

                guard
                    !cleaned.isEmpty
                else {
                    return
                }

                switch self.mode {

                // -----------------------------
                // Normal Dictation
                // -----------------------------

                case .dictation:

                    self.pendingFinalUtterance =
                        cleaned

                    print(
                        "Final dictation received:",
                        cleaned
                    )

                    if self.shouldInsertOnFinal {

                        self.insertPendingUtterance()
                    }

                // -----------------------------
                // Notetaker
                // -----------------------------

                case .notetaker:

                    // Notetaker uses the
                    // diarized speaker segments
                    // as the source of truth.

                    break
                }
            }
            .store(
                in: &cancellables
            )

        // MARK: Dictation Display

        Publishers.CombineLatest(
            socket.$partialTranscript,
            socket.$finalTranscript
        )
        .receive(on: RunLoop.main)
        .sink {

            [weak self]
            partial,
            final in

            guard let self else {
                return
            }

            guard self.mode == .dictation else {
                return
            }

            if !partial.isEmpty {

                self.displayTranscript =
                    partial

            } else if !final.isEmpty {

                self.displayTranscript =
                    final

            } else if self.isListening {

                self.displayTranscript =
                    "Listening..."

            } else {

                self.displayTranscript =
                    "Hold ⌥ Space to speak"
            }
        }
        .store(
            in: &cancellables
        )

        // MARK: Notetaker Partial

        Publishers.CombineLatest(
            socket.$partialTranscript,
            socket.$partialSpeaker
        )
        .receive(on: RunLoop.main)
        .sink { [weak self] text, speaker in

            guard let self else {
                return
            }

            guard
                self.mode == .notetaker
            else {
                return
            }

            let cleaned =
                text
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            self.notePartialTranscript =
                cleaned

            self.notePartialSpeaker =
                cleaned.isEmpty
                ? nil
                : speaker
        }
        .store(
            in: &cancellables
        )

        // MARK: Notetaker Final Fallback

        socket.$finalSegmentTranscript
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] text in

                guard let self else {
                    return
                }

                guard
                    self.mode == .notetaker
                else {
                    return
                }

                let cleaned =
                    text.trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

                guard
                    !cleaned.isEmpty
                else {
                    return
                }

                let fallbackKey =
                    self.normalizedTranscriptKey(
                        cleaned
                    )

                guard
                    !self.noteFinalTranscriptFallbackKeys
                        .contains(
                            fallbackKey
                        )
                else {
                    return
                }

                self.noteFinalTranscriptFallbackKeys
                    .insert(
                        fallbackKey
                    )

                self.noteFinalTranscriptFallbackSegments
                    .append(cleaned)

                self.noteTranscript =
                    self.noteFinalTranscriptFallbackSegments
                        .joined(separator: " ")

                self.notePartialTranscript =
                    ""

                self.notePartialSpeaker =
                    nil
            }
            .store(
                in: &cancellables
            )

        // MARK: Speaker Segments

        socket.$speakerSegments
            .receive(on: RunLoop.main)
            .sink { [weak self] segments in

                guard let self else {
                    return
                }

                guard
                    self.mode == .notetaker
                else {
                    return
                }

                self.noteSpeakerSegments =
                    self.mergeSpeakerSegments(
                        self.noteSpeakerSegmentArchive + segments
                    )

                self.rebuildNoteTranscript()
                self.clearSettledNotePartialTranscript()
            }
            .store(
                in: &cancellables
            )
    }

    // MARK: - Normal Dictation Audio

    private func configureDictationAudio() {

        audioCapture.onAudioData = {

            [weak self] data in

            Task {

                guard let self else {
                    return
                }

                guard
                    self.mode == .dictation
                else {
                    return
                }

                await self.socket
                    .sendAudio(
                        data
                    )
            }
        }

        audioCapture.onAudioLevel = {

            [weak self] level in

            Task { @MainActor in

                guard let self else {
                    return
                }

                guard self.mode == .dictation else {
                    return
                }

                self.updateAudioLevel(
                    level
                )
            }
        }
    }

    // MARK: - Meeting Audio

    private func configureMeetingAudio() {

        meetingAudioCapture.onAudioData = {

            [weak self] data in

            Task {

                guard let self else {
                    return
                }

                guard
                    self.mode == .notetaker
                else {
                    return
                }

                await self.socket
                    .sendAudio(
                        data
                    )
            }
        }

        meetingAudioCapture.onAudioLevel = {

            [weak self] level in

            Task { @MainActor in

                guard let self else {
                    return
                }

                guard self.mode == .notetaker else {
                    return
                }

                self.updateAudioLevel(
                    level
                )
            }
        }
    }

    private func updateAudioLevel(
        _ level: Double
    ) {

        audioLevel =
            (
                audioLevel * 0.65
            )
            +
            (
                level * 0.35
            )
    }

    // MARK: ============================================
    // MARK: DICTIONARY
    // MARK: ============================================

    private func loadDictionaryKeyterms()
        async -> [String] {

        do {

            let keyterms =
                try await DictionaryService
                    .shared
                    .fetchKeyterms()

            print(
                "Loaded dictionary keyterms:",
                keyterms.count
            )

            return keyterms

        } catch {

            // Dictionary failure should NEVER
            // block dictation or Notetaker.

            print(
                "Could not load dictionary keyterms:",
                error
            )

            return []
        }
    }

    // MARK: ============================================
    // MARK: CONNECTION
    // MARK: ============================================

    func connect() {

        socket.connect()
    }

    func disconnect() {

        if isListening {

            switch mode {

            case .dictation:

                stopListening()

                socket.disconnect()

            case .notetaker:

                stopNotetaker(
                    disconnectAfterStopping:
                        true
                )
            }

            return
        }

        socket.disconnect()
    }

    // MARK: ============================================
    // MARK: NORMAL DICTATION
    // MARK: ============================================

    func startListening() {

        guard !isListening else {
            return
        }

        mode =
            .dictation

        Task {

            if !isConnected {

                connect()

                try? await Task.sleep(
                    nanoseconds:
                        250_000_000
                )
            }

            let granted =
                await audioCapture
                    .requestPermission()

            guard granted else {

                microphoneError =
                    "Microphone permission was denied."

                state =
                    .ready

                return
            }

            do {

                socket.finalUtterance =
                    ""

                socket.partialTranscript =
                    ""

                socket.finalTranscript =
                    ""

                pendingFinalUtterance =
                    ""

                shouldInsertOnFinal =
                    false

                isProcessingInsertion =
                    false

                dictationStartedAt =
                    Date()

                lastDictationDurationSeconds =
                    nil

                displayTranscript =
                    "Listening..."

                audioLevel =
                    0

                state =
                    .listening

                // --------------------------------
                // Load custom Dictionary terms
                // before opening Deepgram session.
                // --------------------------------

                let keyterms =
                    await loadDictionaryKeyterms()

                await socket.startListening(
                    keyterms:
                        keyterms
                )

                try? await Task.sleep(
                    nanoseconds:
                        150_000_000
                )

                try audioCapture.start()

                isListening =
                    true

                microphoneError =
                    nil

                print(
                    "FlowVoice dictation started"
                )

                print(
                    "Dictionary keyterms:",
                    keyterms.count
                )

            } catch {

                state =
                    .ready

                microphoneError =
                    "Could not start microphone."

                print(
                    "Could not start dictation:",
                    error
                )

                await socket.stopListening()
            }
        }
    }

    func stopListening() {

        guard isListening else {
            return
        }

        guard mode == .dictation else {

            print(
                "Ignoring dictation stop while Notetaker is active"
            )

            return
        }

        audioCapture.stop()

        isListening =
            false

        audioLevel =
            0

        if let dictationStartedAt {
            lastDictationDurationSeconds =
                max(
                    1,
                    Int(
                        Date()
                            .timeIntervalSince(
                                dictationStartedAt
                            )
                            .rounded()
                    )
                )
        }

        dictationStartedAt =
            nil

        shouldInsertOnFinal =
            true

        state =
            .transcribing

        if !pendingFinalUtterance.isEmpty {

            insertPendingUtterance()
        }

        Task {

            await socket.stopListening()
        }
    }

    // MARK: ============================================
    // MARK: INSERT DICTATION
    // MARK: ============================================

    private func insertPendingUtterance() {

        guard mode == .dictation else {
            return
        }

        guard shouldInsertOnFinal else {
            return
        }

        guard
            !pendingFinalUtterance.isEmpty
        else {

            print(
                "No final utterance ready yet"
            )

            return
        }

        guard
            !isProcessingInsertion
        else {

            print(
                "Dictionary replacement processing already in progress"
            )

            return
        }

        let originalText =
            pendingFinalUtterance

        // Reserve this utterance immediately so
        // the final transcript publisher cannot
        // trigger a duplicate insertion.
        isProcessingInsertion =
            true

        shouldInsertOnFinal =
            false

        pendingFinalUtterance =
            ""

        Task {

            // --------------------------------
            // Apply replacement rules
            //
            // Example:
            //
            // btw -> by the way
            // --------------------------------

            let processedText =
                await DictionaryService
                    .shared
                    .applyReplacements(
                        to:
                            originalText
                    )

            let cleanedProcessedText =
                processedText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

            let finalText =
                cleanedProcessedText.isEmpty
                ? originalText
                : cleanedProcessedText

            if finalText != originalText {

                print(
                    "Dictionary replacement applied:"
                )

                print(
                    "Original:",
                    originalText
                )

                print(
                    "Processed:",
                    finalText
                )

            } else {

                print(
                    "No dictionary replacement needed"
                )
            }

            print(
                "Inserting:",
                finalText
            )

            TextInsertionService
                .shared
                .insertText(
                    finalText
                )

            // IMPORTANT:
            // Set inserted state BEFORE publishing the final transcript.
            // ContentView uses this state to decide whether the transcript
            // should be stored in history.
            state =
                .inserted

            displayTranscript =
                finalText

            isProcessingInsertion =
                false

            try? await Task.sleep(
                nanoseconds:
                    700_000_000
            )

            if mode == .dictation {

                state =
                    .ready
            }
        }
    }

    // MARK: ============================================
    // MARK: NOTETAKER
    // MARK: ============================================

    func startNotetaker(
        resuming: Bool = false
    ) {

        guard !isListening else {
            return
        }

        mode =
            .notetaker

        // Notetaker must NEVER trigger
        // text insertion.

        shouldInsertOnFinal =
            false

        pendingFinalUtterance =
            ""

        isProcessingInsertion =
            false

        if !resuming {

            noteTranscript =
                ""

            notePartialTranscript =
                ""

            notePartialSpeaker =
                nil

            noteSpeakerSegments =
                []

            noteSpeakerSegmentArchive =
                []

            noteFinalTranscriptFallbackSegments =
                []

            noteFinalTranscriptFallbackKeys.removeAll()

            socket.clearSpeakerSegments()
        }

        audioLevel =
            0

        microphoneError =
            nil

        state =
            .listening

        Task {

            if !isConnected {

                connect()

                try? await Task.sleep(
                    nanoseconds:
                        250_000_000
                )
            }

            do {

                socket.finalUtterance =
                    ""

                socket.partialTranscript =
                    ""

                socket.finalTranscript =
                    ""

                if !resuming {

                    socket.clearSpeakerSegments()
                }

                // --------------------------------
                // Load Dictionary keyterms.
                // Same user vocabulary applies
                // to meetings too.
                // --------------------------------

                let keyterms =
                    await loadDictionaryKeyterms()

                await socket.startListening(
                    keyterms:
                        keyterms,
                    audioMode:
                        "meeting_dual_channel"
                )

                try? await Task.sleep(
                    nanoseconds:
                        150_000_000
                )

                // This captures:
                // 1. Mac/system meeting audio
                // 2. Your microphone

                try await meetingAudioCapture
                    .start()

                isListening =
                    true

                microphoneError =
                    nil

                print(
                    "FlowVoice Notetaker started"
                )

                print(
                    "Capturing microphone + system audio"
                )

                print(
                    "Dictionary keyterms:",
                    keyterms.count
                )

            } catch {

                isListening =
                    false

                audioLevel =
                    0

                state =
                    .ready

                mode =
                    .dictation

                shouldInsertOnFinal =
                    false

                pendingFinalUtterance =
                    ""

                isProcessingInsertion =
                    false

                await meetingAudioCapture
                    .stop()

                await socket.stopListening()

                microphoneError =
                    meetingCaptureErrorMessage(
                        error
                    )

                print(
                    "Could not start Notetaker meeting capture:",
                    error
                )
            }
        }
    }

    // MARK: - Stop Notetaker

    func stopNotetaker() {

        stopNotetaker(
            disconnectAfterStopping:
                false
        )
    }

    // MARK: - Pause / Resume Notetaker

    func pauseNotetaker() {

        guard
            isListening,
            mode == .notetaker
        else {
            return
        }

        noteSpeakerSegmentArchive =
            noteSpeakerSegments

        isListening =
            false

        audioLevel =
            0

        notePartialTranscript =
            ""

        notePartialSpeaker =
            nil

        state =
            .ready

        shouldInsertOnFinal =
            false

        pendingFinalUtterance =
            ""

        isProcessingInsertion =
            false

        Task {

            await meetingAudioCapture
                .stop()

            await socket.stopListening()

            socket.clearSpeakerSegments()

            print(
                "FlowVoice Notetaker paused"
            )
        }
    }

    func resumeNotetaker() {

        guard
            !isListening,
            mode == .notetaker
        else {
            return
        }

        startNotetaker(
            resuming: true
        )
    }

    private func stopNotetaker(
        disconnectAfterStopping:
            Bool
    ) {

        guard isListening else {

            if disconnectAfterStopping {

                socket.disconnect()
            }

            return
        }

        guard mode == .notetaker else {
            return
        }

        isListening =
            false

        audioLevel =
            0

        notePartialTranscript =
            ""

        notePartialSpeaker =
            nil

        state =
            .transcribing

        shouldInsertOnFinal =
            false

        pendingFinalUtterance =
            ""

        isProcessingInsertion =
            false

        Task {

            await meetingAudioCapture
                .stop()

            await socket.stopListening()

            print(
                "FlowVoice Notetaker finalizing"
            )

            if disconnectAfterStopping {

                try? await Task.sleep(
                    nanoseconds:
                        100_000_000
                )

                socket.disconnect()
            }
        }
    }

    // MARK: - Meeting Error

    private func meetingCaptureErrorMessage(
        _ error: Error
    ) -> String {

        if let captureError =
            error as? MeetingAudioCaptureError {

            switch captureError {

            case .microphonePermissionDenied:

                return
                    "Microphone permission was denied."

            case .noDisplay:

                return
                    "FlowVoice could not access a display for meeting audio capture."
            }
        }

        return
            "Could not capture meeting audio. Allow FlowVoice in Screen & System Audio Recording and Microphone settings."
    }

    // MARK: - Transcript Key

    private func normalizedTranscriptKey(
        _ text: String
    ) -> String {

        text
            .lowercased()
            .split {
                $0.isWhitespace
                || $0.isNewline
            }
            .joined(
                separator: " "
            )
    }

    // MARK: - Rebuild Notetaker Transcript

    private func rebuildNoteTranscript() {

        guard
            mode == .notetaker
        else {
            return
        }

        let transcript =
            noteSpeakerSegments
                .map {
                    $0.text
                        .trimmingCharacters(
                            in:
                                .whitespacesAndNewlines
                        )
                }
                .filter {
                    !$0.isEmpty
                }
                .joined(
                    separator:
                        " "
                )
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        noteTranscript =
            transcript.isEmpty
            ? noteFinalTranscriptFallbackSegments
                .joined(separator: " ")
            : transcript

        print(
            "Notetaker diarized transcript updated:",
            noteSpeakerSegments.count,
            "segments"
        )
    }

    // MARK: - Live Partial Settling

    private func clearSettledNotePartialTranscript() {

        let partial =
            cleanSegmentText(
                notePartialTranscript
            )

        guard
            !partial.isEmpty,
            !noteSpeakerSegments.isEmpty
        else {
            return
        }

        let recentCommitted =
            noteSpeakerSegments
                .suffix(3)
                .map { $0.text }
                .joined(separator: " ")

        let committedKey =
            normalizedTranscriptKey(
                recentCommitted
            )

        let partialKey =
            normalizedTranscriptKey(
                partial
            )

        guard
            !committedKey.isEmpty,
            !partialKey.isEmpty
        else {
            return
        }

        let partialIsCommitted =
            committedKey.contains(
                partialKey
            )
            || isLikelySameAudio(
                recentCommitted,
                partial
            )
            || isLikelySameAudio(
                partial,
                recentCommitted
            )

        if partialIsCommitted {

            notePartialTranscript =
                ""

            notePartialSpeaker =
                nil
        }
    }

    // MARK: - Speaker Segment Cleanup

    private func mergeSpeakerSegments(
        _ segments: [NoteSpeakerSegment]
    ) -> [NoteSpeakerSegment] {

        var merged:
            [NoteSpeakerSegment] = []

        for segment in segments {

            let text =
                cleanSegmentText(
                    segment.text
                )

            guard
                !text.isEmpty
            else {
                continue
            }

            let cleanedSegment =
                NoteSpeakerSegment(
                    id: segment.id,
                    speaker: segment.speaker,
                    text: text,
                    start: segment.start,
                    end: segment.end
                )

            guard
                let previous = merged.last
            else {
                merged.append(
                    cleanedSegment
                )
                continue
            }

            if previous.speaker != cleanedSegment.speaker,
               !isLikelySameAudio(
                    previous.text,
                    cleanedSegment.text
               ) {

                merged.append(
                    cleanedSegment
                )
                continue
            }

            let mergedText =
                mergeSegmentText(
                    previous.text,
                    cleanedSegment.text
                )

            merged[merged.count - 1] =
                NoteSpeakerSegment(
                    id: previous.id,
                    speaker: previous.speaker,
                    text: mergedText,
                    start: previous.start ?? cleanedSegment.start,
                    end: latestSegmentEnd(
                        previous.end,
                        cleanedSegment.end
                    )
                )
        }

        return merged
    }

    private func cleanSegmentText(
        _ text: String
    ) -> String {

        text
            .split {
                $0.isWhitespace
                || $0.isNewline
            }
            .joined(
                separator: " "
            )
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
    }

    private func mergeSegmentText(
        _ previous: String,
        _ next: String
    ) -> String {

        let previousWords =
            normalizedWords(
                previous
            )

        let nextWords =
            normalizedWords(
                next
            )

        guard
            !previousWords.isEmpty,
            !nextWords.isEmpty
        else {
            return cleanSegmentText(
                previous + " " + next
            )
        }

        if previousWords == nextWords {
            return previous
        }

        if nextWords.starts(
            with: previousWords
        ) {
            return next
        }

        if previousWords.starts(
            with: nextWords
        ) {
            return previous
        }

        let overlap =
            overlappingWordCount(
                previousWords,
                nextWords
            )

        let nextParts =
            next.split {
                $0.isWhitespace
                || $0.isNewline
            }

        if overlap > 0,
           overlap < nextParts.count {

            return cleanSegmentText(
                previous + " " + nextParts
                    .dropFirst(overlap)
                    .joined(separator: " ")
            )
        }

        return cleanSegmentText(
            previous + " " + next
        )
    }

    private func normalizedWords(
        _ text: String
    ) -> [String] {

        text
            .lowercased()
            .components(
                separatedBy:
                    CharacterSet
                    .alphanumerics
                    .inverted
            )
            .filter {
                !$0.isEmpty
            }
    }

    private func isLikelySameAudio(
        _ previous: String,
        _ next: String
    ) -> Bool {

        let previousWords =
            normalizedWords(
                previous
            )

        let nextWords =
            normalizedWords(
                next
            )

        guard
            min(
                previousWords.count,
                nextWords.count
            ) >= 4
        else {
            return false
        }

        if wordSimilarity(
            previousWords,
            nextWords
        ) >= 0.58 {
            return true
        }

        let overlap =
            max(
                overlappingWordCount(
                    previousWords,
                    nextWords
                ),
                overlappingWordCount(
                    nextWords,
                    previousWords
                )
            )

        return overlap >= min(
            5,
            min(
                previousWords.count,
                nextWords.count
            )
        )
    }

    private func wordSimilarity(
        _ previous: [String],
        _ next: [String]
    ) -> Double {

        let previousSet =
            Set(previous)

        let nextSet =
            Set(next)

        let smallerCount =
            min(
                previousSet.count,
                nextSet.count
            )

        guard smallerCount > 0 else {
            return 0
        }

        let sharedCount =
            previousSet
                .intersection(
                    nextSet
                )
                .count

        return Double(sharedCount)
            / Double(smallerCount)
    }

    private func overlappingWordCount(
        _ previous: [String],
        _ next: [String]
    ) -> Int {

        let maximumOverlap =
            min(
                previous.count,
                next.count
            )

        guard
            maximumOverlap > 0
        else {
            return 0
        }

        for count in stride(
            from: maximumOverlap,
            through: 1,
            by: -1
        ) {

            if Array(previous.suffix(count)) == Array(next.prefix(count)) {
                return count
            }
        }

        return 0
    }

    private func latestSegmentEnd(
        _ first: Double?,
        _ second: Double?
    ) -> Double? {

        switch (first, second) {

        case let (.some(first), .some(second)):
            return max(first, second)

        case let (.some(first), .none):
            return first

        case let (.none, .some(second)):
            return second

        case (.none, .none):
            return nil
        }
    }

    // MARK: - Reset Notetaker

    func resetNotetaker() {

        noteTranscript =
            ""

        notePartialTranscript =
            ""

        notePartialSpeaker =
            nil

        noteSpeakerSegments =
            []

        noteSpeakerSegmentArchive =
            []

        noteFinalTranscriptFallbackSegments =
            []

        noteFinalTranscriptFallbackKeys.removeAll()

        socket.clearSpeakerSegments()

        pendingFinalUtterance =
            ""

        shouldInsertOnFinal =
            false

        isProcessingInsertion =
            false

        audioLevel =
            0

        isListening =
            false

        mode =
            .dictation

        state =
            .ready

        displayTranscript =
            "Hold ⌥ Space to speak"

        print(
            "FlowVoice Notetaker reset"
        )
    }
}

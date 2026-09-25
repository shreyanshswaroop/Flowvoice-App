import Foundation
import Combine

@MainActor
final class FlowVoiceSocket: ObservableObject {

    @Published var isConnected = false
    @Published var statusText = "Disconnected"

    @Published var partialTranscript = ""
    @Published var partialSpeaker: Int?
    @Published var finalTranscript = ""
    @Published var finalSegmentTranscript = ""
    @Published var finalUtterance = ""

    @Published var speakerSegments:
        [NoteSpeakerSegment] = []

    private var speakerSegmentKeys =
        Set<String>()

    private var socketTask:
        URLSessionWebSocketTask?

    private var session:
        URLSession?

    private var keepsPartialUntilSpeakerSegment = false

    func connect() {

        guard socketTask == nil else {
            return
        }

        guard let url = URL(
            string: APIConfig.webSocketURL
        ) else {

            statusText =
                "Invalid URL"

            return
        }

        let configuration =
            URLSessionConfiguration.default

        let session =
            URLSession(
                configuration:
                    configuration
            )

        self.session =
            session

        let task =
            session.webSocketTask(
                with: url
            )

        socketTask =
            task

        task.resume()

        statusText =
            "Connecting..."

        receiveLoop()
    }

    func disconnect() {

        socketTask?.cancel(
            with:
                .normalClosure,
            reason:
                nil
        )

        socketTask =
            nil

        session =
            nil

        isConnected =
            false

        statusText =
            "Disconnected"

        partialTranscript =
            ""

        partialSpeaker =
            nil

        finalTranscript =
            ""

        finalSegmentTranscript =
            ""

        finalUtterance =
            ""

        speakerSegments =
            []

        speakerSegmentKeys.removeAll()

        keepsPartialUntilSpeakerSegment = false
    }

    // MARK: - Audio

    func sendAudio(
        _ data: Data
    ) async {

        guard let socketTask else {
            return
        }

        do {

            try await socketTask.send(
                .data(data)
            )

        } catch {

            print(
                "Audio send error:",
                error
            )
        }
    }

    // MARK: - Plain Control

    func sendControl(
        _ message: String
    ) async {

        guard let socketTask else {
            return
        }

        do {

            try await socketTask.send(
                .string(
                    message
                )
            )

        } catch {

            print(
                "Control send error:",
                error
            )
        }
    }

    // MARK: - Start Listening With Dictionary

    func startListening(
        keyterms: [String],
        audioMode: String = "dictation"
    ) async {

        guard let socketTask else {
            return
        }

        let cleanedKeyterms =
            cleanKeyterms(
                keyterms
            )

        let payload:
            [String: Any] = [

                "type":
                    "start_listening",

                "keyterms":
                    cleanedKeyterms,

                "audio_mode":
                    audioMode,
            ]

        finalSegmentTranscript =
            ""

        partialTranscript =
            ""

        partialSpeaker =
            nil

        keepsPartialUntilSpeakerSegment = (
            audioMode == "meeting_dual_channel"
        )

        do {

            let data =
                try JSONSerialization
                    .data(
                        withJSONObject:
                            payload
                    )

            guard let json =
                String(
                    data:
                        data,
                    encoding:
                        .utf8
                )
            else {

                print(
                    "Could not encode start_listening payload"
                )

                return
            }

            try await socketTask.send(
                .string(
                    json
                )
            )

            print(
                "Start listening sent with",
                cleanedKeyterms.count,
                "dictionary keyterms"
            )

        } catch {

            print(
                "Start listening send error:",
                error
            )
        }
    }

    // MARK: - Stop Listening

    func stopListening() async {

        await sendControl(
            "stop_listening"
        )
    }

    // MARK: - Clean Keyterms

    private func cleanKeyterms(
        _ values: [String]
    ) -> [String] {

        var results:
            [String] = []

        var seen =
            Set<String>()

        for value in values {

            let cleaned =
                value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

            guard
                !cleaned.isEmpty
            else {
                continue
            }

            let normalized =
                cleaned.lowercased()

            guard
                !seen.contains(
                    normalized
                )
            else {
                continue
            }

            seen.insert(
                normalized
            )

            results.append(
                cleaned
            )

            if results.count >= 100 {
                break
            }
        }

        return results
    }

    // MARK: - Speaker Segments

    func clearSpeakerSegments() {

        speakerSegments =
            []

        speakerSegmentKeys.removeAll()
    }

    // MARK: - Receive Loop

    private func receiveLoop() {

        guard let socketTask else {
            return
        }

        socketTask.receive {

            [weak self] result in

            guard let self else {
                return
            }

            Task {

                @MainActor in

                switch result {

                case .success(
                    let message
                ):

                    self.handle(
                        message
                    )

                    self.receiveLoop()

                case .failure(
                    let error
                ):

                    print(
                        "WebSocket receive error:",
                        error
                    )

                    self.isConnected =
                        false

                    self.statusText =
                        "Disconnected"

                    self.socketTask =
                        nil
                }
            }
        }
    }

    // MARK: - Handle Message

    private func handle(
        _ message:
            URLSessionWebSocketTask.Message
    ) {

        switch message {

        case .string(
            let text
        ):

            handleJSON(
                text
            )

        case .data(
            let data
        ):

            if let text =
                String(
                    data:
                        data,
                    encoding:
                        .utf8
                ) {

                handleJSON(
                    text
                )
            }

        @unknown default:

            break
        }
    }

    // MARK: - Handle JSON

    private func handleJSON(
        _ text: String
    ) {

        guard let data =
            text.data(
                using:
                    .utf8
            )
        else {
            return
        }

        guard let json =
            try?
                JSONSerialization
                .jsonObject(
                    with:
                        data
                )
                as? [String: Any]
        else {

            print(
                "Invalid JSON:",
                text
            )

            return
        }

        guard let type =
            json[
                "type"
            ] as? String
        else {
            return
        }

        switch type {

        case "connection":

            isConnected =
                true

            statusText =
                "Connected"

        case "listening_started":

            statusText =
                "Listening"

            if let keytermCount =
                json[
                    "keyterm_count"
                ] as? Int {

                print(
                    "Deepgram session started with",
                    keytermCount,
                    "keyterms"
                )
            }

        case "listening_stopped":

            statusText =
                isConnected
                ? "Connected"
                : "Disconnected"

        case "transcript_partial":

            partialTranscript =
                json[
                    "text"
                ] as? String
                ?? ""

            partialSpeaker =
                json[
                    "speaker"
                ] as? Int

        case "transcript_final":

            let text =
                json[
                    "text"
                ] as? String
                ?? ""

            finalTranscript =
                text

            finalSegmentTranscript =
                text

            if !keepsPartialUntilSpeakerSegment {

                partialTranscript =
                    ""

                partialSpeaker =
                    nil
            }

        case "utterance_final":

            let text =
                json[
                    "text"
                ] as? String
                ?? ""

            finalUtterance =
                text

            finalTranscript =
                text

            partialTranscript =
                ""

            partialSpeaker =
                nil

        case "speaker_segments":

            handleSpeakerSegments(
                json
            )

        case "dictation_complete":

            partialTranscript =
                ""

            partialSpeaker =
                nil

        case "error":

            statusText =
                json[
                    "message"
                ] as? String
                ?? "Backend error"

        default:

            break
        }
    }

    // MARK: - Decode Speaker Segments

    private func handleSpeakerSegments(
        _ json: [String: Any]
    ) {

        guard let segmentObjects =
            json[
                "segments"
            ] as? [[String: Any]]
        else {

            print(
                "Invalid speaker_segments payload"
            )

            return
        }

        let decodedSegments =
            segmentObjects.compactMap {

                object
                -> NoteSpeakerSegment? in

                guard let speaker =
                    object[
                        "speaker"
                    ] as? Int
                else {
                    return nil
                }

                guard let text =
                    object[
                        "text"
                    ] as? String
                else {
                    return nil
                }

                let cleanedText =
                    text
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )

                guard
                    !cleanedText.isEmpty
                else {
                    return nil
                }

                let start =
                    numberAsDouble(
                        object[
                            "start"
                        ]
                    )

                let end =
                    numberAsDouble(
                        object[
                            "end"
                        ]
                    )

                return NoteSpeakerSegment(
                    speaker:
                        speaker,
                    text:
                        cleanedText,
                    start:
                        start,
                    end:
                        end
                )
            }

        guard
            !decodedSegments.isEmpty
        else {
            return
        }

        let newSegments =
            decodedSegments.filter {
                segment in

                let key =
                    speakerSegmentKey(
                        segment
                    )

                guard
                    !speakerSegmentKeys
                        .contains(
                            key
                        )
                else {
                    return false
                }

                speakerSegmentKeys
                    .insert(
                        key
                    )

                return true
            }

        guard
            !newSegments.isEmpty
        else {
            return
        }

        speakerSegments.append(
            contentsOf:
                newSegments
        )

        print(
            "Received new speaker segments:",
            newSegments.count,
            "total:",
            speakerSegments.count
        )
    }

    // MARK: - Segment Key

    private func speakerSegmentKey(
        _ segment: NoteSpeakerSegment
    ) -> String {

        let normalizedText =
            segment.text
                .lowercased()
                .split {
                    $0.isWhitespace
                    || $0.isNewline
                }
                .joined(
                    separator: " "
                )

        let start =
            segment.start
                .map {
                    String(
                        format: "%.2f",
                        $0
                    )
                }
            ?? "nil"

        let end =
            segment.end
                .map {
                    String(
                        format: "%.2f",
                        $0
                    )
                }
            ?? "nil"

        return "\(segment.speaker)|\(start)|\(end)|\(normalizedText)"
    }

    // MARK: - Number Helper

    private func numberAsDouble(
        _ value: Any?
    ) -> Double? {

        if let value =
            value as? Double {

            return value
        }

        if let value =
            value as? Int {

            return Double(
                value
            )
        }

        if let value =
            value as? NSNumber {

            return value.doubleValue
        }

        return nil
    }
}

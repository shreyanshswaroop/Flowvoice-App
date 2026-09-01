import Foundation
import AVFoundation
import ScreenCaptureKit
import CoreMedia

@available(macOS 15.0, *)
final class MeetingAudioCaptureService:
    NSObject,
    SCStreamOutput,
    SCStreamDelegate {

    var onAudioData: ((Data) -> Void)?
    var onAudioLevel: ((Double) -> Void)?

    private var stream: SCStream?

    private let captureQueue =
        DispatchQueue(
            label: "flowvoice.meeting.capture"
        )

    private let processingQueue =
        DispatchQueue(
            label: "flowvoice.meeting.processing"
        )

    private var isRunning = false

    private let targetSampleRate: Double = 16_000
    private let targetChannels: AVAudioChannelCount = 1

    private var systemConverter: AVAudioConverter?
    private var microphoneConverter: AVAudioConverter?

    // Buffers used to combine
    // microphone + meeting audio.
    private var pendingSystemSamples: [Int16] = []
    private var pendingMicrophoneSamples: [Int16] = []

    private let mixChunkSize = 1600

    // MARK: - Permissions

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(
                for: .audio
            ) { granted in
                continuation.resume(
                    returning: granted
                )
            }
        }
    }
    

    // MARK: - Start

    func start() async throws {

        guard !isRunning else {
            return
        }

        let microphoneGranted =
            await requestMicrophonePermission()

        guard microphoneGranted else {
            throw MeetingAudioCaptureError
                .microphonePermissionDenied
        }

        let content =
            try await SCShareableContent
                .excludingDesktopWindows(
                    false,
                    onScreenWindowsOnly: true
                )

        guard let display =
            content.displays.first
        else {
            throw MeetingAudioCaptureError
                .noDisplay
        }

        let filter =
            SCContentFilter(
                display: display,
                excludingWindows: []
            )

        let configuration =
            SCStreamConfiguration()

        // MARK: System / meeting audio

        configuration.capturesAudio = true

        configuration.excludesCurrentProcessAudio = true

        // Ask ScreenCaptureKit for exactly
        // the format Deepgram already expects.

        configuration.sampleRate =
            Int(targetSampleRate)

        configuration.channelCount =
            Int(targetChannels)

        // MARK: Microphone

        configuration.captureMicrophone = true

        if let microphone =
            AVCaptureDevice.default(
                for: .audio
            ) {

            configuration
                .microphoneCaptureDeviceID =
                microphone.uniqueID
        }

        // MARK: Lightweight screen output

        // SCStream is still display-backed, so
        // ScreenCaptureKit may produce video frames.
        //
        // We do not use video in FlowVoice.
        // Keeping this tiny minimizes overhead.

        configuration.width = 2
        configuration.height = 2

        configuration.minimumFrameInterval =
            CMTime(
                value: 1,
                timescale: 1
            )

        configuration.queueDepth = 3

        let stream =
            SCStream(
                filter: filter,
                configuration: configuration,
                delegate: self
            )

        // MARK: System audio output

        try stream.addStreamOutput(
            self,
            type: .audio,
            sampleHandlerQueue: captureQueue
        )

        // MARK: Microphone output

        try stream.addStreamOutput(
            self,
            type: .microphone,
            sampleHandlerQueue: captureQueue
        )

        // MARK: Screen output

        // We intentionally ignore these frames.
        // Registering this output prevents
        // ScreenCaptureKit from repeatedly logging
        // "stream output NOT found. Dropping frame".

        try stream.addStreamOutput(
            self,
            type: .screen,
            sampleHandlerQueue: captureQueue
        )

        self.stream = stream

        pendingSystemSamples = []
        pendingMicrophoneSamples = []

        try await stream.startCapture()

        isRunning = true

        print(
            "Meeting audio capture started"
        )
    }

    // MARK: - Stop

    func stop() async {

        guard isRunning else {
            return
        }

        isRunning = false

        if let stream {

            do {

                try await stream
                    .stopCapture()

            } catch {

                print(
                    "Could not stop meeting capture:",
                    error
                )
            }
        }

        stream = nil

        systemConverter = nil
        microphoneConverter = nil

        pendingSystemSamples = []
        pendingMicrophoneSamples = []

        onAudioLevel?(0)

        print(
            "Meeting audio capture stopped"
        )
    }

    // MARK: - ScreenCaptureKit Output

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of outputType: SCStreamOutputType
    ) {

        guard
            sampleBuffer.isValid,
            CMSampleBufferDataIsReady(
                sampleBuffer
            )
        else {
            return
        }

        switch outputType {

        case .audio:

            processSampleBuffer(
                sampleBuffer,
                source: .system
            )

        case .microphone:

            processSampleBuffer(
                sampleBuffer,
                source: .microphone
            )

        case .screen:

            // Intentionally ignored.
            //
            // FlowVoice only needs:
            // - system audio
            // - microphone audio
            //
            // We register the screen output only
            // so ScreenCaptureKit has somewhere
            // to deliver display frames.

            break

        default:

            break
        }
    }

    // MARK: - Stream Failure

    func stream(
        _ stream: SCStream,
        didStopWithError error: Error
    ) {

        print(
            "Meeting capture stopped with error:",
            error
        )

        isRunning = false
    }

    // MARK: - Source

    private enum AudioSource {
        case system
        case microphone
    }

    // MARK: - Process Sample

    private func processSampleBuffer(
        _ sampleBuffer: CMSampleBuffer,
        source: AudioSource
    ) {

        guard let formatDescription =
            CMSampleBufferGetFormatDescription(
                sampleBuffer
            )
        else {
            return
        }

        guard let asbd =
            CMAudioFormatDescriptionGetStreamBasicDescription(
                formatDescription
            )
        else {
            return
        }

        let inputFormat =
            AVAudioFormat(
                streamDescription: asbd
            )

        guard let inputFormat else {
            return
        }

        let frameCount =
            CMSampleBufferGetNumSamples(
                sampleBuffer
            )

        guard frameCount > 0 else {
            return
        }

        guard let pcmBuffer =
            AVAudioPCMBuffer(
                pcmFormat: inputFormat,
                frameCapacity:
                    AVAudioFrameCount(
                        frameCount
                    )
            )
        else {
            return
        }

        pcmBuffer.frameLength =
            AVAudioFrameCount(
                frameCount
            )

        let status =
            CMSampleBufferCopyPCMDataIntoAudioBufferList(
                sampleBuffer,
                at: 0,
                frameCount:
                    Int32(
                        frameCount
                    ),
                into:
                    pcmBuffer
                        .mutableAudioBufferList
            )

        guard status == noErr else {

            print(
                "Could not copy meeting audio:",
                status
            )

            return
        }

        calculateAudioLevel(
            from: pcmBuffer
        )

        convert(
            buffer: pcmBuffer,
            source: source
        )
    }

    // MARK: - Convert to 16k Int16 Mono

    private func convert(
        buffer: AVAudioPCMBuffer,
        source: AudioSource
    ) {

        guard let outputFormat =
            AVAudioFormat(
                commonFormat: .pcmFormatInt16,
                sampleRate: targetSampleRate,
                channels: targetChannels,
                interleaved: true
            )
        else {
            return
        }

        let converter: AVAudioConverter?

        switch source {

        case .system:

            if
                systemConverter == nil
                || systemConverter?
                    .inputFormat != buffer.format
            {

                systemConverter =
                    AVAudioConverter(
                        from: buffer.format,
                        to: outputFormat
                    )
            }

            converter =
                systemConverter

        case .microphone:

            if
                microphoneConverter == nil
                || microphoneConverter?
                    .inputFormat != buffer.format
            {

                microphoneConverter =
                    AVAudioConverter(
                        from: buffer.format,
                        to: outputFormat
                    )
            }

            converter =
                microphoneConverter
        }

        guard let converter else {
            return
        }

        let ratio =
            outputFormat.sampleRate
            /
            buffer.format.sampleRate

        let outputCapacity =
            AVAudioFrameCount(
                Double(
                    buffer.frameLength
                )
                * ratio
            )
            + 32

        guard let convertedBuffer =
            AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: outputCapacity
            )
        else {
            return
        }

        var conversionError: NSError?

        var supplied = false

        let inputBlock:
            AVAudioConverterInputBlock = {
                _,
                status in

                if supplied {

                    status.pointee =
                        .noDataNow

                    return nil
                }

                supplied = true

                status.pointee =
                    .haveData

                return buffer
            }

        converter.convert(
            to: convertedBuffer,
            error: &conversionError,
            withInputFrom: inputBlock
        )

        if let conversionError {

            print(
                "Meeting audio conversion error:",
                conversionError
            )

            return
        }

        guard
            convertedBuffer.frameLength > 0,
            let pointer =
                convertedBuffer
                    .int16ChannelData?[0]
        else {
            return
        }

        let sampleCount =
            Int(
                convertedBuffer
                    .frameLength
            )

        let samples =
            Array(
                UnsafeBufferPointer(
                    start: pointer,
                    count: sampleCount
                )
            )

        processingQueue.async {
            [weak self] in

            self?.queueSamples(
                samples,
                source: source
            )
        }
    }

    // MARK: - Queue Samples

    private func queueSamples(
        _ samples: [Int16],
        source: AudioSource
    ) {

        switch source {

        case .system:

            pendingSystemSamples
                .append(
                    contentsOf: samples
                )

        case .microphone:

            pendingMicrophoneSamples
                .append(
                    contentsOf: samples
                )
        }

        mixAvailableSamples()
    }

    // MARK: - Mix

    private func mixAvailableSamples() {

        while
            pendingSystemSamples.count >= mixChunkSize
            ||
            pendingMicrophoneSamples.count >= mixChunkSize
        {

            var mixed =
                [Int16](
                    repeating: 0,
                    count: mixChunkSize
                )

            for index in 0..<mixChunkSize {

                let systemSample: Int32

                if index <
                    pendingSystemSamples.count {

                    systemSample =
                        Int32(
                            pendingSystemSamples[
                                index
                            ]
                        )

                } else {

                    systemSample = 0
                }

                let microphoneSample: Int32

                if index <
                    pendingMicrophoneSamples.count {

                    microphoneSample =
                        Int32(
                            pendingMicrophoneSamples[
                                index
                            ]
                        )

                } else {

                    microphoneSample = 0
                }

                // Mix both sources.
                //
                // Dividing by 2 prevents
                // clipping when both are loud.

                let value =
                    (
                        systemSample
                        +
                        microphoneSample
                    )
                    / 2

                let clamped =
                    max(
                        Int32(
                            Int16.min
                        ),
                        min(
                            Int32(
                                Int16.max
                            ),
                            value
                        )
                    )

                mixed[index] =
                    Int16(
                        clamped
                    )
            }

            if pendingSystemSamples.count
                >= mixChunkSize {

                pendingSystemSamples
                    .removeFirst(
                        mixChunkSize
                    )

            } else {

                pendingSystemSamples
                    .removeAll(
                        keepingCapacity: true
                    )
            }

            if pendingMicrophoneSamples.count
                >= mixChunkSize {

                pendingMicrophoneSamples
                    .removeFirst(
                        mixChunkSize
                    )

            } else {

                pendingMicrophoneSamples
                    .removeAll(
                        keepingCapacity: true
                    )
            }

            let data =
                mixed.withUnsafeBytes {
                    rawBuffer in

                    Data(
                        rawBuffer
                    )
                }

            DispatchQueue.main.async {
                [weak self] in

                self?
                    .onAudioData?(
                        data
                    )
            }
        }
    }

    // MARK: - Level

    private func calculateAudioLevel(
        from buffer: AVAudioPCMBuffer
    ) {

        guard let channelData =
            buffer
                .floatChannelData?[0]
        else {
            return
        }

        let frameLength =
            Int(
                buffer.frameLength
            )

        guard frameLength > 0 else {
            return
        }

        var sum: Float = 0

        for index in 0..<frameLength {

            let sample =
                channelData[
                    index
                ]

            sum +=
                sample * sample
        }

        let rms =
            sqrt(
                sum
                /
                Float(
                    frameLength
                )
            )

        let minDB: Float = -60

        let safeRMS =
            max(
                rms,
                0.000001
            )

        let db =
            max(
                20
                    * log10(
                        safeRMS
                    ),
                minDB
            )

        let normalized =
            Double(
                (
                    db
                    - minDB
                )
                /
                -minDB
            )

        let level =
            min(
                max(
                    normalized,
                    0
                ),
                1
            )

        DispatchQueue.main.async {
            [weak self] in

            self?
                .onAudioLevel?(
                    level
                )
        }
    }
}

enum MeetingAudioCaptureError:
    Error {

    case microphonePermissionDenied
    case noDisplay
}

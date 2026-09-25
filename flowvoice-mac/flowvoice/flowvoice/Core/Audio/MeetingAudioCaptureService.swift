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

    // Buffers used to pair microphone + meeting audio without flattening them
    // into one noisy mono track.
    private var pendingSystemSamples: [Int16] = []
    private var pendingMicrophoneSamples: [Int16] = []

    private let mixChunkSize = 1_536
    private let maxAlignmentLagSamples = 9_600
    private let minAlignmentOverlapSamples = 6_400
    private let alignmentSearchStride = 32
    private let minAlignmentCorrelation = 0.12
    private let maxLinearEchoGain = 1.25
    private let doubleTalkResidualRatio = 0.08
    private let robustGainSegments = 8
    private let robustGainMinSegments = 3

    private let neuralEchoCanceller = NeuralEchoCanceller()

    private var currentAlignmentLag = 0
    private var echoGain: Double = 0

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
        currentAlignmentLag = 0
        echoGain = 0
        neuralEchoCanceller?.reset()

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
        currentAlignmentLag = 0
        echoGain = 0

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

        emitAvailableSamples()
    }

    // MARK: - Emit

    private func emitAvailableSamples() {

        while
            pendingSystemSamples.count >= mixChunkSize
            &&
            pendingMicrophoneSamples.count >= mixChunkSize
        {

            updateAlignmentIfNeeded()

            guard
                pendingSystemSamples.count >= mixChunkSize,
                pendingMicrophoneSamples.count >= mixChunkSize
            else {
                return
            }

            let systemChunk =
                takeChunk(
                    from: &pendingSystemSamples,
                    size: mixChunkSize
                )

            let microphoneChunk =
                takeChunk(
                    from: &pendingMicrophoneSamples,
                    size: mixChunkSize
                )

            let cleanedMicrophoneChunk =
                echoReducedMicrophone(
                    microphoneChunk,
                    reference: systemChunk
                )

            var interleaved = [Int16]()

            interleaved.reserveCapacity(
                mixChunkSize * 2
            )

            for index in 0..<mixChunkSize {

                // Channel 0: local microphone.
                interleaved.append(
                    cleanedMicrophoneChunk[index]
                )

                // Channel 1: system / meeting audio.
                interleaved.append(
                    systemChunk[index]
                )
            }

            let data =
                interleaved.withUnsafeBytes {
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

    private func updateAlignmentIfNeeded() {

        let requiredSamples =
            maxAlignmentLagSamples
            + minAlignmentOverlapSamples

        guard
            pendingSystemSamples.count >= requiredSamples,
            pendingMicrophoneSamples.count >= requiredSamples
        else {
            return
        }

        let windowSize =
            min(
                pendingSystemSamples.count,
                pendingMicrophoneSamples.count,
                requiredSamples
            )

        let systemWindow =
            Array(
                pendingSystemSamples
                    .prefix(
                        windowSize
                    )
            )

        let microphoneWindow =
            Array(
                pendingMicrophoneSamples
                    .prefix(
                        windowSize
                    )
            )

        guard let lag =
            strongestAlignmentLag(
                microphone: microphoneWindow,
                system: systemWindow
            )
        else {
            return
        }

        guard lag != currentAlignmentLag else {
            return
        }

        applyAlignmentLag(
            lag
        )

        currentAlignmentLag = lag
        echoGain = 0
        neuralEchoCanceller?.reset()
    }

    private func strongestAlignmentLag(
        microphone: [Int16],
        system: [Int16]
    ) -> Int? {

        var bestLag = currentAlignmentLag
        var bestCorrelation = 0.0

        let lowerBound =
            -maxAlignmentLagSamples

        let upperBound =
            maxAlignmentLagSamples

        for lag in
            stride(
                from: lowerBound,
                through: upperBound,
                by: alignmentSearchStride
            )
        {

            let correlation =
                alignmentCorrelation(
                    microphone: microphone,
                    system: system,
                    lag: lag
                )

            if correlation > bestCorrelation {
                bestCorrelation = correlation
                bestLag = lag
            }
        }

        guard bestCorrelation >= minAlignmentCorrelation else {
            return nil
        }

        return bestLag
    }

    private func alignmentCorrelation(
        microphone: [Int16],
        system: [Int16],
        lag: Int
    ) -> Double {

        let micStart =
            max(
                lag,
                0
            )

        let systemStart =
            max(
                -lag,
                0
            )

        let overlap =
            min(
                microphone.count - micStart,
                system.count - systemStart
            )

        guard overlap >= minAlignmentOverlapSamples else {
            return 0
        }

        var micEnergy = 0.0
        var systemEnergy = 0.0
        var crossEnergy = 0.0

        for offset in 0..<overlap {

            let mic =
                Double(
                    microphone[
                        micStart + offset
                    ]
                )

            let ref =
                Double(
                    system[
                        systemStart + offset
                    ]
                )

            micEnergy += mic * mic
            systemEnergy += ref * ref
            crossEnergy += mic * ref
        }

        guard
            micEnergy > 0,
            systemEnergy > 0
        else {
            return 0
        }

        return
            abs(
                crossEnergy
            )
            /
            max(
                sqrt(
                    micEnergy * systemEnergy
                ),
                1
            )
    }

    private func applyAlignmentLag(
        _ lag: Int
    ) {

        if lag > 0 {

            let samplesToDrop =
                min(
                    lag,
                    pendingMicrophoneSamples.count
                )

            pendingMicrophoneSamples.removeFirst(
                samplesToDrop
            )

            return
        }

        if lag < 0 {

            let samplesToDrop =
                min(
                    -lag,
                    pendingSystemSamples.count
                )

            pendingSystemSamples.removeFirst(
                samplesToDrop
            )
        }
    }

    private func takeChunk(
        from samples: inout [Int16],
        size: Int
    ) -> [Int16] {

        if samples.count >= size {

            let chunk =
                Array(
                    samples.prefix(
                        size
                    )
                )

            samples.removeFirst(
                size
            )

            return chunk
        }

        var chunk = samples

        samples.removeAll(
            keepingCapacity: true
        )

        if chunk.count < size {

            chunk.append(
                contentsOf:
                    repeatElement(
                        0,
                        count: size - chunk.count
                    )
            )
        }

        return chunk
    }

    private func echoReducedMicrophone(
        _ microphone: [Int16],
        reference system: [Int16]
    ) -> [Int16] {

        guard microphone.count == system.count else {
            return microphone
        }

        let processedMicrophone =
            neuralEchoCanceller?.process(
                microphone: microphone,
                system: system
            )
            ?? microphone

        var micEnergy = 0.0
        var systemEnergy = 0.0
        var crossEnergy = 0.0

        for index in processedMicrophone.indices {

            let mic =
                Double(
                    processedMicrophone[index]
                )

            let ref =
                Double(
                    system[index]
                )

            micEnergy += mic * mic
            systemEnergy += ref * ref
            crossEnergy += mic * ref
        }

        let sampleCount =
            Double(
                microphone.count
            )

        let micRms =
            sqrt(
                micEnergy / sampleCount
            )

        let systemRms =
            sqrt(
                systemEnergy / sampleCount
            )

        guard
            micRms > 120,
            systemRms > 120
        else {
            echoGain *= 0.85
            return processedMicrophone
        }

        let correlation =
            crossEnergy
            /
            max(
                sqrt(
                    micEnergy * systemEnergy
                ),
                1
            )

        guard abs(correlation) > 0.18 else {
            echoGain *= 0.85
            return processedMicrophone
        }

        let instantaneousGain =
            min(
                max(
                    crossEnergy
                    /
                    max(
                        systemEnergy,
                        1
                    ),
                    -maxLinearEchoGain
                ),
                maxLinearEchoGain
            )

        let residualEnergy =
            max(
                micEnergy
                -
                (
                    crossEnergy * crossEnergy
                    /
                    max(
                        systemEnergy,
                        1
                    )
                ),
                0
            )

        let residualRatio =
            sqrt(
                residualEnergy / sampleCount
            )
            /
            max(
                micRms,
                1
            )

        let measuredGain =
            residualRatio > doubleTalkResidualRatio
            ? segmentedTrimmedGain(
                microphone: processedMicrophone,
                system: system,
                initialGain: instantaneousGain
            )
            : instantaneousGain

        echoGain =
            echoGain
            +
            (
                measuredGain
                - echoGain
            )
            * 0.12

        let gain =
            residualRatio > doubleTalkResidualRatio
            ? echoGain
            : measuredGain

        return processedMicrophone.indices.map { index in

            let cleaned =
                Double(
                    processedMicrophone[index]
                )
                -
                Double(
                    system[index]
                )
                * gain

            return Int16(
                max(
                    Double(
                        Int16.min
                    ),
                    min(
                        Double(
                            Int16.max
                        ),
                        cleaned
                    )
                )
            )
        }
    }

    private func segmentedTrimmedGain(
        microphone: [Int16],
        system: [Int16],
        initialGain: Double
    ) -> Double {

        let length =
            min(
                microphone.count,
                system.count
            )

        guard length > 0 else {
            return initialGain
        }

        let segmentLength =
            max(
                length / robustGainSegments,
                1
            )

        var gains: [Double] = []
        gains.reserveCapacity(
            robustGainSegments
        )

        var start = 0

        while start < length {

            let end =
                min(
                    start + segmentLength,
                    length
                )

            var systemEnergy = 0.0
            var crossEnergy = 0.0

            for index in start..<end {

                let ref =
                    Double(
                        system[index]
                    )

                let mic =
                    Double(
                        microphone[index]
                    )

                systemEnergy += ref * ref
                crossEnergy += mic * ref
            }

            if systemEnergy > 1 {

                let gain =
                    min(
                        max(
                            crossEnergy / systemEnergy,
                            -maxLinearEchoGain
                        ),
                        maxLinearEchoGain
                    )

                gains.append(
                    gain
                )
            }

            start = end
        }

        guard gains.count >= robustGainMinSegments else {
            return initialGain
        }

        gains.sort()

        let trimCount =
            gains.count >= 5
            ? 1
            : 0

        let trimmed =
            gains[
                trimCount..<(gains.count - trimCount)
            ]

        guard !trimmed.isEmpty else {
            return initialGain
        }

        let total =
            trimmed.reduce(
                0.0,
                +
            )

        return total
            /
            Double(
                trimmed.count
            )
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

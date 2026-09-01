import Foundation
import AVFoundation

final class AudioCaptureService {

    private let audioEngine = AVAudioEngine()
    private var converter: AVAudioConverter?

    private let targetSampleRate: Double = 16_000
    private let targetChannels: AVAudioChannelCount = 1

    private var isRunning = false

    var onAudioData: ((Data) -> Void)?
    var onAudioLevel: ((Double) -> Void)?

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() throws {
        guard !isRunning else {
            return
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        guard let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: true
        ) else {
            throw AudioCaptureError.invalidOutputFormat
        }

        guard let converter = AVAudioConverter(
            from: inputFormat,
            to: outputFormat
        ) else {
            throw AudioCaptureError.converterCreationFailed
        }

        self.converter = converter

        inputNode.installTap(
            onBus: 0,
            bufferSize: 1024,
            format: inputFormat
        ) { [weak self] buffer, _ in
            guard let self else {
                return
            }

            self.calculateAudioLevel(
                from: buffer
            )

            self.process(
                buffer: buffer,
                outputFormat: outputFormat
            )
        }

        audioEngine.prepare()

        try audioEngine.start()

        isRunning = true

        print("Microphone capture started")
    }

    func stop() {
        guard isRunning else {
            return
        }

        audioEngine.inputNode.removeTap(
            onBus: 0
        )

        audioEngine.stop()

        converter = nil
        isRunning = false

        onAudioLevel?(0)

        print("Microphone capture stopped")
    }

    private func calculateAudioLevel(
        from buffer: AVAudioPCMBuffer
    ) {
        guard
            let channelData = buffer.floatChannelData?[0]
        else {
            return
        }

        let frameLength =
            Int(buffer.frameLength)

        guard frameLength > 0 else {
            return
        }

        var sum: Float = 0

        for index in 0..<frameLength {
            let sample =
                channelData[index]

            sum += sample * sample
        }

        let rms = sqrt(
            sum / Float(frameLength)
        )

        let minDB: Float = -60

        let db = max(
            20 * log10(rms),
            minDB
        )

        let normalized =
            Double(
                (db - minDB)
                / -minDB
            )

        let level = min(
            max(
                normalized,
                0
            ),
            1
        )

        onAudioLevel?(level)
    }

    private func process(
        buffer: AVAudioPCMBuffer,
        outputFormat: AVAudioFormat
    ) {
        guard let converter else {
            return
        }

        let ratio =
            outputFormat.sampleRate
            / buffer.format.sampleRate

        let outputFrameCapacity =
            AVAudioFrameCount(
                Double(buffer.frameLength)
                * ratio
            ) + 1

        guard let convertedBuffer =
            AVAudioPCMBuffer(
                pcmFormat: outputFormat,
                frameCapacity: outputFrameCapacity
            )
        else {
            return
        }

        var error: NSError?
        var suppliedBuffer = false

        let inputBlock:
            AVAudioConverterInputBlock = {
                _, outStatus in

                if suppliedBuffer {
                    outStatus.pointee = .noDataNow
                    return nil
                }

                suppliedBuffer = true
                outStatus.pointee = .haveData

                return buffer
            }

        converter.convert(
            to: convertedBuffer,
            error: &error,
            withInputFrom: inputBlock
        )

        if let error {
            print(
                "Audio conversion error:",
                error
            )

            return
        }

        guard
            convertedBuffer.frameLength > 0,
            let dataPointer =
                convertedBuffer.int16ChannelData
        else {
            return
        }

        let frameLength =
            Int(convertedBuffer.frameLength)

        let byteCount =
            frameLength
            * MemoryLayout<Int16>.size

        let data = Data(
            bytes: dataPointer[0],
            count: byteCount
        )

        onAudioData?(data)
    }
}

enum AudioCaptureError: Error {
    case invalidOutputFormat
    case converterCreationFailed
}

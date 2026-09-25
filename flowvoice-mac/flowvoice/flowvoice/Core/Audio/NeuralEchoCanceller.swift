import Foundation

final class NeuralEchoCanceller {

    private let handle: OpaquePointer

    init?() {

        guard let handle = flowvoice_aec_create() else {
            return nil
        }

        self.handle = handle
    }

    deinit {
        flowvoice_aec_destroy(
            handle
        )
    }

    func reset() {
        flowvoice_aec_reset(
            handle
        )
    }

    func process(
        microphone: [Int16],
        system: [Int16]
    ) -> [Int16]? {

        guard
            !microphone.isEmpty,
            microphone.count == system.count
        else {
            return nil
        }

        var output =
            Array(
                repeating: Int16(0),
                count: microphone.count
            )

        let written =
            microphone.withUnsafeBufferPointer { microphoneBuffer in

                system.withUnsafeBufferPointer { systemBuffer in

                    output.withUnsafeMutableBufferPointer { outputBuffer in

                        flowvoice_aec_process(
                            handle,
                            microphoneBuffer.baseAddress,
                            systemBuffer.baseAddress,
                            outputBuffer.baseAddress,
                            microphone.count
                        )
                    }
                }
            }

        guard written == microphone.count else {
            return nil
        }

        return output
    }
}

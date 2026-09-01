import SwiftUI
import AppKit

struct FloatingVoiceView: View {

    @ObservedObject var controller: FlowVoiceController

    @State private var recordingStartedAt = Date()
    @State private var lastRecordedSeconds = 0

    private let controlHeight: CGFloat = 48
    private let mainWidth: CGFloat = 132

    var body: some View {
        ZStack {
            Color.clear
            recordingControl
        }
        .frame(width: 150, height: 64)
        .background(Color.clear)
        .onAppear {
            if controller.state == .listening {
                recordingStartedAt = Date()
                lastRecordedSeconds = 0
            }
        }
        .onChange(of: controller.state) { oldState, newState in
            if newState == .listening {
                recordingStartedAt = Date()
                lastRecordedSeconds = 0
            }

            if oldState == .listening && newState == .transcribing {
                lastRecordedSeconds = max(
                    0,
                    Int(Date().timeIntervalSince(recordingStartedAt))
                )
            }
        }
    }

    // MARK: - Main Pill

    private var recordingControl: some View {
        HStack(spacing: 14) {
            leadingIndicator
            statusText
        }
        .padding(.horizontal, 16)
        .frame(
            width: mainWidth,
            height: controlHeight
        )
        .background {
            Capsule()
                .fill(
                    Color(nsColor: .windowBackgroundColor)
                        .opacity(0.96)
                )
        }
        .overlay {
            Capsule()
                .stroke(
                    Color.primary.opacity(0.08),
                    lineWidth: 0.8
                )
        }
        .shadow(
            color: .black.opacity(0.10),
            radius: 8,
            x: 0,
            y: 3
        )
    }

    // MARK: - Left Indicator

    @ViewBuilder
    private var leadingIndicator: some View {
        switch controller.state {
        case .listening:
            FlowVoiceMiniWaveform(
                level: controller.audioLevel
            )

        case .transcribing:
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.small)
                .scaleEffect(0.85)
                .frame(width: 18, height: 18)

        case .inserted:
            Image(systemName: "checkmark")
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.green)
                .frame(width: 18, height: 18)

        case .ready:
            FlowVoiceMiniWaveform(
                level: 0.08
            )
        }
    }

    // MARK: - Right Text

    @ViewBuilder
    private var statusText: some View {
        switch controller.state {
        case .listening:
            liveTimerText

        case .transcribing:
            Text(formattedRecordedTime())
                .font(
                    .system(
                        size: 18,
                        weight: .regular
                    )
                )
                .monospacedDigit()
                .foregroundStyle(Color.primary.opacity(0.88))

        case .inserted:
            Text("Done")
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(Color.primary.opacity(0.88))

        case .ready:
            Text("0:00")
                .font(
                    .system(
                        size: 18,
                        weight: .regular
                    )
                )
                .monospacedDigit()
                .foregroundStyle(Color.primary.opacity(0.88))
        }
    }

    // MARK: - Live Timer

    private var liveTimerText: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(formattedTime(at: context.date))
                .font(
                    .system(
                        size: 18,
                        weight: .regular
                    )
                )
                .monospacedDigit()
                .foregroundStyle(Color.primary.opacity(0.88))
        }
    }

    private func formattedTime(at date: Date) -> String {
        let duration = max(
            0,
            Int(date.timeIntervalSince(recordingStartedAt))
        )

        return stringFromSeconds(duration)
    }

    private func formattedRecordedTime() -> String {
        stringFromSeconds(lastRecordedSeconds)
    }

    private func stringFromSeconds(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        return String(
            format: "%d:%02d",
            minutes,
            remainingSeconds
        )
    }
}


// MARK: - FlowVoice Mini Waveform

struct FlowVoiceMiniWaveform: View {

    let level: Double

    private let multipliers: [Double] = [
        0.34,
        0.62,
        1.00,
        0.76,
        0.92,
        0.52
    ]

    var body: some View {
        HStack(
            alignment: .center,
            spacing: 2.5
        ) {
            ForEach(
                Array(multipliers.enumerated()),
                id: \.offset
            ) { index, multiplier in
                waveformBar(
                    index: index,
                    multiplier: multiplier
                )
            }
        }
        .frame(width: 34, height: 24)
    }

    private func waveformBar(
        index: Int,
        multiplier: Double
    ) -> some View {
        let normalizedLevel = min(
            max(level * 2.5, 0.12),
            1
        )

        let variation =
            index.isMultiple(of: 2)
            ? 1.0
            : 0.86

        let height = 4 + (
            normalizedLevel
            * 18
            * multiplier
            * variation
        )

        return Capsule()
            .fill(Color.primary.opacity(0.82))
            .frame(
                width: 3.2,
                height: height
            )
            .animation(
                .interactiveSpring(
                    response: 0.16,
                    dampingFraction: 0.72
                ),
                value: level
            )
    }
}

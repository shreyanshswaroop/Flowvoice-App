import AppKit
import SwiftUI
import QuartzCore

final class LiveNoteWindowController: NSObject, NSWindowDelegate {

    private let panel: NSPanel
    private let onFinish: () -> Void
    private var appearanceObserver: NSObjectProtocol?
    private var isProgrammaticClose = false

    private let panelWidth: CGFloat = 430
    private let panelHeight: CGFloat = 720

    init(
        controller: FlowVoiceController,
        title: Binding<String>,
        elapsedSeconds: Binding<Int>,
        isFinalizing: Binding<Bool>,
        onFinish: @escaping () -> Void
    ) {

        self.onFinish =
            onFinish

        panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: panelWidth,
                height: panelHeight
            ),
            styleMask: [
                .titled,
                .closable,
                .fullSizeContentView
            ],
            backing: .buffered,
            defer: false
        )

        super.init()

        panel.delegate =
            self

        panel.title =
            "Live Note"

        panel.titleVisibility =
            .hidden

        panel.titlebarAppearsTransparent =
            true

        panel.isFloatingPanel =
            true

        panel.level =
            .floating

        panel.hidesOnDeactivate =
            false

        panel.isReleasedWhenClosed =
            false

        panel.backgroundColor =
            FlowVoiceTheme.nsWindowBackground

        panel.isOpaque =
            true

        panel.hasShadow =
            true

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        panel.minSize =
            NSSize(
                width: 390,
                height: 560
            )

        applyAppearance()

        appearanceObserver =
            NotificationCenter.default.addObserver(
                forName: .flowVoiceAppearanceChanged,
                object: nil,
                queue: .main
            ) { [weak self] notification in

                guard let appearance =
                    notification.object as? FlowVoiceAppearance
                else {
                    return
                }

                self?.applyAppearance(
                    appearance
                )
            }

        let hostingView =
            NSHostingView(
                rootView:
                    LiveNoteSidePanelView(
                        controller: controller,
                        title: title,
                        elapsedSeconds: elapsedSeconds,
                        isFinalizing: isFinalizing,
                        onFinish: onFinish
                    )
            )

        hostingView.frame = NSRect(
            x: 0,
            y: 0,
            width: panelWidth,
            height: panelHeight
        )

        hostingView.autoresizingMask = [
            .width,
            .height
        ]

        panel.contentView =
            hostingView
    }

    deinit {

        if let appearanceObserver {

            NotificationCenter.default.removeObserver(
                appearanceObserver
            )
        }
    }

    func show() {

        updatePosition()

        panel.alphaValue =
            0

        panel.makeKeyAndOrderFront(
            nil
        )

        NSAnimationContext.runAnimationGroup { context in

            context.duration =
                0.12

            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeOut
                )

            panel
                .animator()
                .alphaValue = 1
        }
    }

    func close() {

        isProgrammaticClose =
            true

        panel.close()
    }

    func windowShouldClose(
        _ sender: NSWindow
    ) -> Bool {

        guard !isProgrammaticClose else {
            return true
        }

        onFinish()

        return false
    }

    private func applyAppearance(
        _ appearance: FlowVoiceAppearance = .stored
    ) {

        panel.appearance =
            appearance.nsAppearance

        panel.backgroundColor =
            FlowVoiceTheme.nsWindowBackground
    }

    private func updatePosition() {

        let mainWindow =
            NSApplication.shared.windows.first {
                $0.isVisible &&
                !($0 is NSPanel)
            }

        let screen =
            mainWindow?.screen
            ?? NSScreen.main

        guard let screen else {
            return
        }

        let visibleFrame =
            screen.visibleFrame

        let anchorFrame =
            mainWindow?.frame
            ?? visibleFrame

        let x =
            min(
                max(
                    anchorFrame.maxX - panelWidth + 26,
                    visibleFrame.minX + 18
                ),
                visibleFrame.maxX - panelWidth - 18
            )

        let y =
            min(
                max(
                    anchorFrame.maxY - panelHeight - 8,
                    visibleFrame.minY + 18
                ),
                visibleFrame.maxY - panelHeight - 18
            )

        panel.setFrame(
            NSRect(
                x: x,
                y: y,
                width: panelWidth,
                height: panelHeight
            ),
            display: false
        )
    }
}

private struct LiveNoteSidePanelView: View {

    @ObservedObject var controller: FlowVoiceController

    @Binding var title: String
    @Binding var elapsedSeconds: Int
    @Binding var isFinalizing: Bool

    let onFinish: () -> Void

    private var liveTranscript: String {

        let final =
            controller.noteTranscript.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let partial =
            controller.notePartialTranscript.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        if final.isEmpty {
            return partial
        }

        if partial.isEmpty {
            return final
        }

        return final + " " + partial
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 0
        ) {

            header

            Divider()
                .overlay(
                    FlowVoiceTheme.divider
                )

            transcriptContent

            Spacer(minLength: 0)

            footer
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(
            FlowVoiceTheme.pageBackground
        )
    }

    private var header: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack {

                HStack(spacing: 8) {

                    Circle()
                        .fill(Color.red)
                        .frame(
                            width: 7,
                            height: 7
                        )

                    Text("Recording")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )

                Spacer()

                Text(
                    formattedDuration(
                        elapsedSeconds
                    )
                )
                .font(
                    .system(
                        size: 12,
                        weight: .medium,
                        design: .monospaced
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
            }

            TextField(
                "New note",
                text: $title
            )
            .textFieldStyle(.plain)
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
        }
        .padding(.horizontal, 28)
        .padding(.top, 48)
        .padding(.bottom, 24)
    }

    private var transcriptContent: some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack {

                HStack(spacing: 7) {

                    Image(systemName: "waveform")
                        .font(
                            .system(
                                size: 12,
                                weight: .medium
                            )
                        )

                    Text("Transcript")
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                }
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )

                Spacer()
            }

            ScrollView {

                if controller.noteSpeakerSegments.isEmpty {

                    Text(
                        liveTranscript.isEmpty
                        ? "Words will appear here as the note builds."
                        : liveTranscript
                    )
                    .font(
                        .system(
                            size: 14,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        liveTranscript.isEmpty
                        ? FlowVoiceTheme.tertiaryText
                        : FlowVoiceTheme.primaryText
                    )
                    .lineSpacing(5)
                    .frame(
                        maxWidth: .infinity,
                        alignment: .topLeading
                    )
                    .textSelection(.enabled)

                } else {

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

                        ForEach(
                            controller.noteSpeakerSegments
                        ) { segment in

                            LiveNoteSpeakerRow(
                                segment: segment
                            )
                        }
                    }
                }
            }
        }
        .padding(18)
        .background {

            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        }
        .overlay {

            RoundedRectangle(
                cornerRadius: 8,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        }
        .padding(.horizontal, 28)
        .padding(.top, 28)
    }

    private var footer: some View {

        HStack(spacing: 12) {

            Button {
                onFinish()
            } label: {

                HStack(spacing: 8) {

                    if isFinalizing {

                        ProgressView()
                            .controlSize(.small)

                    } else {

                        Image(systemName: "checkmark")

                        Text("Finish note")
                    }
                }
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.accentButtonText
                )
                .frame(
                    maxWidth: .infinity
                )
                .frame(height: 44)
                .background(
                    FlowVoiceTheme.accentButton,
                    in: RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                )
            }
            .buttonStyle(.plain)
            .disabled(isFinalizing)
        }
        .padding(28)
    }

    private func formattedDuration(
        _ seconds: Int
    ) -> String {

        let minutes =
            seconds / 60

        let remainingSeconds =
            seconds % 60

        return String(
            format: "%d:%02d",
            minutes,
            remainingSeconds
        )
    }
}

private struct LiveNoteSpeakerRow: View {

    let segment: NoteSpeakerSegment

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text("Speaker \(segment.speaker + 1)")
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

            Text(segment.text)
                .font(
                    .system(
                        size: 14,
                        weight: .regular
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
                .lineSpacing(5)
                .textSelection(.enabled)
        }
    }

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
}

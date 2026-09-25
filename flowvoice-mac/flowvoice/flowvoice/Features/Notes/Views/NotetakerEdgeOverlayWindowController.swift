import AppKit
import SwiftUI
import QuartzCore

@MainActor
final class NotetakerEdgeOverlayWindowController {

    private let panel: NSPanel
    private let controller: FlowVoiceController
    private let title: Binding<String>
    private let elapsedSeconds: Binding<Int>

    private var shouldShow = false
    private var appearanceObserver: NSObjectProtocol?
    private var resignObserver: NSObjectProtocol?
    private var activeObserver: NSObjectProtocol?
    private var miniaturizeObserver: NSObjectProtocol?
    private var deminiaturizeObserver: NSObjectProtocol?

    private let panelSize = NSSize(width: 340, height: 240)
    private let edgeGap: CGFloat = 12

    init(
        controller: FlowVoiceController,
        title: Binding<String>,
        elapsedSeconds: Binding<Int>
    ) {

        self.controller = controller
        self.title = title
        self.elapsedSeconds = elapsedSeconds

        panel = NSPanel(
            contentRect: NSRect(
                origin: .zero,
                size: panelSize
            ),
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]

        applyDarkGlassAppearance()

        let hostingView =
            TransparentHostingView(
                rootView:
                    NotetakerEdgeOverlayView(
                        controller: controller,
                        title: title,
                        elapsedSeconds: elapsedSeconds,
                        onExpansionChanged: { [weak self] expanded in
                            self?.handleExpansionChanged(expanded)
                        },
                        onActivateApp: {
                            AppWindowManager.shared.bringMainWindowToFront()
                        }
                    )
            )

        hostingView.frame = NSRect(origin: .zero, size: panelSize)
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView

        appearanceObserver =
            NotificationCenter.default.addObserver(
                forName: .flowVoiceAppearanceChanged,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor [weak self] in
                    self?.applyDarkGlassAppearance()
                }
            }

        resignObserver =
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor [weak self] in
                    self?.syncVisibility()
                }
            }

        activeObserver =
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor [weak self] in
                    self?.syncVisibility()
                }
            }

        miniaturizeObserver =
            NotificationCenter.default.addObserver(
                forName: NSWindow.didMiniaturizeNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor [weak self] in
                    self?.syncVisibility()
                }
            }

        deminiaturizeObserver =
            NotificationCenter.default.addObserver(
                forName: NSWindow.didDeminiaturizeNotification,
                object: nil,
                queue: .main
            ) { _ in
                Task { @MainActor [weak self] in
                    self?.syncVisibility()
                }
            }
    }

    deinit {

        [
            appearanceObserver,
            resignObserver,
            activeObserver,
            miniaturizeObserver,
            deminiaturizeObserver
        ]
        .compactMap { $0 }
        .forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }

    func begin() {

        shouldShow = true
        syncVisibility()
    }

    func end() {

        shouldShow = false
        hide()
    }

    private func syncVisibility() {

        guard shouldShow else {
            hide()
            return
        }

        if NSApplication.shared.isActive && !isMainWindowMiniaturized {
            hide()
        } else {
            show()
        }
    }

    private func show() {

        updateFrame(animated: false)

        guard !panel.isVisible else {
            return
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func hide() {

        guard panel.isVisible else {
            return
        }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.10
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                panel.animator().alphaValue = 0
            },
            completionHandler: {
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
            }
        )
    }

    private func updateFrame(
        animated: Bool
    ) {

        guard let screen =
            NSScreen.main
        else {
            return
        }

        let visibleFrame =
            screen.visibleFrame

        let x =
            visibleFrame.maxX
            - panelSize.width
            - edgeGap

        let y =
            visibleFrame.midY
            - panelSize.height / 2

        let frame =
            NSRect(
                x: x,
                y: y,
                width: panelSize.width,
                height: panelSize.height
            )

        if animated {

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.18
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                panel.animator().setFrame(frame, display: true)
            }

        } else {

            panel.setFrame(frame, display: true)
        }
    }

    private func applyDarkGlassAppearance() {

        panel.appearance =
            NSAppearance(
                named: .darkAqua
            )
    }

    private func handleExpansionChanged(
        _ expanded: Bool
    ) {

        if expanded {
            panel.orderFrontRegardless()
        }
    }

    private var isMainWindowMiniaturized:
        Bool {

        NSApplication.shared.windows.contains {
            window in

            window.isVisible &&
            !(window is NSPanel) &&
            window.isMiniaturized
        }
    }
}

private struct NotetakerEdgeOverlayView:
    View {

    @ObservedObject var controller:
        FlowVoiceController

    @Binding var title:
        String

    @Binding var elapsedSeconds:
        Int

    let onExpansionChanged:
        (Bool) -> Void

    let onActivateApp:
        () -> Void

    @State private var isExpanded =
        false

    private var liveTranscript:
        String {

        let final =
            controller.noteTranscript
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let partial =
            controller.notePartialTranscript
                .trimmingCharacters(in: .whitespacesAndNewlines)

        if final.isEmpty {
            return partial
        }

        if partial.isEmpty {
            return final
        }

        return final + " " + partial
    }

    var body: some View {

        ZStack(alignment: .trailing) {

            if isExpanded {
                expandedPanel
                    .transition(.scale(scale: 0.94, anchor: .trailing).combined(with: .opacity))
            } else {
                edgePill
                    .transition(.opacity)
            }
        }
        .frame(
            width: 340,
            height: 240,
            alignment: .trailing
        )
        .animation(
            .spring(response: 0.22, dampingFraction: 0.88),
            value: isExpanded
        )
    }

    private var edgePill:
        some View {

        VStack(spacing: 0) {

            Button {
                setExpanded(false)
                onActivateApp()
            } label: {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(FlowVoiceTheme.secondaryText)
                    .frame(width: 36, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Open FlowVoice")

            Rectangle()
                .fill(Color(nsColor: .separatorColor).opacity(0.18))
                .frame(height: 1)
                .padding(.horizontal, 8)

            Image(systemName: "text.bubble.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.72))
                .frame(width: 36, height: 31)
                .contentShape(Rectangle())
                .onHover { hovering in
                    if hovering {
                        setExpanded(true)
                    }
                }
                .help("Show transcript")
        }
        .frame(width: 36, height: 64)
        .background(
            Color(nsColor: .windowBackgroundColor).opacity(0.96),
            in: Capsule()
        )
        .overlay {
            Capsule()
                .strokeBorder(Color(nsColor: .separatorColor).opacity(0.42), lineWidth: 1)
        }
        .contentShape(Capsule())
    }

    private var expandedPanel:
        some View {

        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 8) {

                Circle()
                    .fill(Color.red.opacity(0.86))
                    .frame(width: 6, height: 6)

                Text("Recording")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.68))

                Spacer()

                Text(formattedDuration(elapsedSeconds))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.48))
            }
            .padding(.horizontal, 14)
            .padding(.top, 13)
            .padding(.bottom, 10)

            Divider()
                .overlay(.white.opacity(0.14))

            ScrollView {

                VStack(alignment: .trailing, spacing: 8) {

                    if controller.noteSpeakerSegments.isEmpty {

                        if liveTranscript.isEmpty {

                            Text("Transcript will appear here.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.46))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 52)

                        } else {

                            transcriptBubble(
                                committed: controller.noteTranscript,
                                partial: controller.notePartialTranscript
                            )
                        }

                    } else {

                        ForEach(controller.noteSpeakerSegments) { segment in
                            transcriptBubble(
                                committed: segment.text,
                                partial: ""
                            )
                        }

                        if !controller.notePartialTranscript.isEmpty {
                            transcriptBubble(
                                committed: "",
                                partial: controller.notePartialTranscript
                            )
                        }
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .frame(width: 340, height: 240)
        .background {
            NotetakerGlassBackground(cornerRadius: 18)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.38),
                            .white.opacity(0.08),
                            .black.opacity(0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(.white.opacity(0.10), lineWidth: 0.5)
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onHover { hovering in
            if !hovering {
                setExpanded(false)
            }
        }
        .onTapGesture {
            onActivateApp()
        }
    }

    private func transcriptBubble(
        committed: String,
        partial: String
    ) -> some View {

        let cleanCommitted =
            committed
                .trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanPartial =
            partial
                .trimmingCharacters(in: .whitespacesAndNewlines)

        var styledText =
            AttributedString()

        if !cleanCommitted.isEmpty {
            var committedRun =
                AttributedString(cleanCommitted)

            committedRun.foregroundColor =
                .white.opacity(0.94)

            styledText +=
                committedRun
        }

        if !cleanPartial.isEmpty {
            if !cleanCommitted.isEmpty {
                styledText +=
                    AttributedString(" ")
            }

            var partialRun =
                AttributedString(cleanPartial)

            partialRun.foregroundColor =
                .white.opacity(0.62)

            styledText +=
                partialRun

            var dotsRun =
                AttributedString("  ...")

            dotsRun.foregroundColor =
                .white.opacity(0.58)

            styledText +=
                dotsRun
        }

        return Text(styledText)
            .font(.system(size: 12, weight: .regular))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(
                Color.white.opacity(
                    cleanPartial.isEmpty
                    ? 0.20
                    : 0.26
                ),
                in: RoundedRectangle(cornerRadius: 11, style: .continuous)
            )
            .frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
            .transaction { transaction in
                transaction.animation = nil
            }
    }

    private func setExpanded(
        _ expanded: Bool
    ) {

        guard isExpanded != expanded else {
            return
        }

        withAnimation(.spring(response: 0.22, dampingFraction: 0.86)) {
            isExpanded = expanded
        }

        onExpansionChanged(expanded)
    }

    private func formattedDuration(
        _ seconds: Int
    ) -> String {

        String(
            format: "%d:%02d",
            seconds / 60,
            seconds % 60
        )
    }
}

private struct NotetakerGlassBackground:
    NSViewRepresentable {

    let cornerRadius:
        CGFloat

    func makeNSView(
        context: Context
    ) -> NSVisualEffectView {

        let view =
            NSVisualEffectView()

        view.material =
            .hudWindow

        view.blendingMode =
            .behindWindow

        view.state =
            .active

        view.wantsLayer =
            true

        view.layer?.cornerRadius =
            cornerRadius

        view.layer?.cornerCurve =
            .continuous

        view.layer?.masksToBounds =
            true

        return view
    }

    func updateNSView(
        _ view: NSVisualEffectView,
        context: Context
    ) {

        view.material =
            .hudWindow

        view.blendingMode =
            .behindWindow

        view.state =
            .active

        view.layer?.cornerRadius =
            cornerRadius
    }
}

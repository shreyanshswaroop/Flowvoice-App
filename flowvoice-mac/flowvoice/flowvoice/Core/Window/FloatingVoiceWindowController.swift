import AppKit
import SwiftUI
import QuartzCore

final class FloatingVoiceWindowController {

    private let panel: NSPanel
    private var hideWorkItem: DispatchWorkItem?

    private let panelWidth: CGFloat = 150
    private let panelHeight: CGFloat = 68

    init(
        controller: FlowVoiceController
    ) {

        panel = NSPanel(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: panelWidth,
                height: panelHeight
            ),
            styleMask: [
                .borderless,
                .nonactivatingPanel
            ],
            backing: .buffered,
            defer: false
        )

        // MARK: - Panel

        panel.isFloatingPanel = true
        panel.level = .statusBar

        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false

        panel.hidesOnDeactivate = false

        panel.ignoresMouseEvents = true

        panel.isReleasedWhenClosed = false

        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle
        ]

        // MARK: - SwiftUI Hosting

        let hostingView =
            TransparentHostingView(
                rootView:
                    FloatingVoiceView(
                        controller: controller
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

    // MARK: - Show

    func show() {

        DispatchQueue.main.async { [weak self] in

            guard let self else {
                return
            }

            self.hideWorkItem?.cancel()
            self.hideWorkItem = nil

            self.updatePosition()

            // If already visible, don't animate again.
            if self.panel.isVisible {
                self.panel.alphaValue = 1
                return
            }

            self.panel.alphaValue = 0

            self.panel.orderFrontRegardless()

            NSAnimationContext.runAnimationGroup { context in

                context.duration = 0.10

                context.timingFunction =
                    CAMediaTimingFunction(
                        name: .easeOut
                    )

                self.panel
                    .animator()
                    .alphaValue = 1
            }
        }
    }

    // MARK: - Hide

    func hide(
        after delay: TimeInterval = 0
    ) {

        hideWorkItem?.cancel()

        let workItem =
            DispatchWorkItem {
                [weak self] in

                guard let self else {
                    return
                }

                guard self.panel.isVisible else {
                    return
                }

                NSAnimationContext.runAnimationGroup(
                    { context in

                        context.duration = 0.08

                        context.timingFunction =
                            CAMediaTimingFunction(
                                name: .easeIn
                            )

                        self.panel
                            .animator()
                            .alphaValue = 0
                    },
                    completionHandler: {

                        self.panel.orderOut(nil)

                        self.panel.alphaValue = 1
                    }
                )
            }

        hideWorkItem =
            workItem

        if delay == 0 {

            DispatchQueue.main.async(
                execute: workItem
            )

        } else {

            DispatchQueue.main.asyncAfter(
                deadline: .now() + delay,
                execute: workItem
            )
        }
    }

    // MARK: - Position

    private func updatePosition() {

        guard let screen =
                NSScreen.main
        else {
            return
        }

        let visibleFrame =
            screen.visibleFrame

        let x =
            visibleFrame.midX
            -
            panelWidth / 2

        let y =
            visibleFrame.minY
            + 28

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


// MARK: - Transparent Hosting View

final class TransparentHostingView<Content: View>:
    NSHostingView<Content> {

    override var isOpaque: Bool {
        false
    }

    required init(
        rootView: Content
    ) {

        super.init(
            rootView: rootView
        )

        wantsLayer = true

        layer?.backgroundColor =
            NSColor.clear.cgColor

        layer?.isOpaque =
            false

        layer?.masksToBounds =
            false
    }

    @available(*, unavailable)
    required init?(
        coder: NSCoder
    ) {

        fatalError(
            "init(coder:) has not been implemented"
        )
    }

    override func viewDidMoveToWindow() {

        super.viewDidMoveToWindow()

        wantsLayer = true

        layer?.backgroundColor =
            NSColor.clear.cgColor

        layer?.isOpaque =
            false

        layer?.masksToBounds =
            false

        window?.backgroundColor =
            .clear

        window?.isOpaque =
            false

        window?.hasShadow =
            false
    }
}

import AppKit
import QuartzCore

@MainActor
final class AppWindowManager {

    static let shared = AppWindowManager()

    private init() {}

    private var dashboardFrame: NSRect?

    // MARK: - Auth Window

    func showAuthWindow() {

        guard let window = mainWindow else {
            return
        }

        restoreNormalWindowBehaviour(
            window
        )

        let targetFrame: NSRect

        if let dashboardFrame {

            targetFrame = dashboardFrame

        } else {

            let targetSize = NSSize(
                width: 1320,
                height: 860
            )

            targetFrame = centeredFrame(
                for: targetSize,
                on: window
            )

            dashboardFrame = targetFrame
        }

        window.setFrame(
            targetFrame,
            display: true,
            animate: true
        )

        window.makeKeyAndOrderFront(
            nil
        )
    }

    // MARK: - External Auth Window

    func showExternalAuthWindow() {

        guard let window = mainWindow else {
            return
        }

        let targetSize = NSSize(
            width: 340,
            height: 430
        )

        let screen =
            window.screen
            ?? NSScreen.main

        guard let screen else {
            return
        }

        let visibleFrame =
            screen.visibleFrame

        let rightPadding: CGFloat = 24

        let x =
            visibleFrame.maxX
            - targetSize.width
            - rightPadding

        let y =
            visibleFrame.midY
            - targetSize.height / 2

        let targetFrame = NSRect(
            x: x,
            y: y,
            width: targetSize.width,
            height: targetSize.height
        )

        // Keep FlowVoice above Safari while
        // Google authentication is active.
        window.level = .floating

        window.hidesOnDeactivate = false

        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        NSAnimationContext.runAnimationGroup {
            context in

            context.duration = 0.28

            context.timingFunction =
                CAMediaTimingFunction(
                    name: .easeInEaseOut
                )

            window.animator().setFrame(
                targetFrame,
                display: true
            )
        }

        window.orderFrontRegardless()
    }

    // MARK: - Expand To Dashboard

    func expandToDashboardWindow() async {

        guard let window = mainWindow else {
            return
        }

        let targetFrame: NSRect

        if let dashboardFrame {

            targetFrame = dashboardFrame

        } else {

            let targetSize = NSSize(
                width: 1320,
                height: 860
            )

            targetFrame = centeredFrame(
                for: targetSize,
                on: window
            )

            dashboardFrame = targetFrame
        }

        await withCheckedContinuation {
            continuation in

            NSAnimationContext.runAnimationGroup {
                context in

                context.duration = 0.48

                context.timingFunction =
                    CAMediaTimingFunction(
                        name: .easeInEaseOut
                    )

                window.animator().setFrame(
                    targetFrame,
                    display: true
                )

            } completionHandler: {

                continuation.resume()
            }
        }

        restoreNormalWindowBehaviour(
            window
        )

        window.makeKeyAndOrderFront(
            nil
        )

        NSApplication.shared.activate(
            ignoringOtherApps: true
        )
    }

    // MARK: - Normal Window Behaviour

    private func restoreNormalWindowBehaviour(
        _ window: NSWindow
    ) {

        window.level = .normal

        window.hidesOnDeactivate = false

        window.collectionBehavior = [
            .managed
        ]
    }

    // MARK: - Centered Frame

    private func centeredFrame(
        for size: NSSize,
        on window: NSWindow
    ) -> NSRect {

        let screen =
            window.screen
            ?? NSScreen.main

        guard let screen else {

            return NSRect(
                origin: .zero,
                size: size
            )
        }

        let visibleFrame =
            screen.visibleFrame

        return NSRect(
            x:
                visibleFrame.midX
                - size.width / 2,
            y:
                visibleFrame.midY
                - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    // MARK: - Main Window

    private var mainWindow: NSWindow? {

        NSApplication.shared.windows.first {
            $0.isVisible &&
            !($0 is NSPanel)
        }
    }
}

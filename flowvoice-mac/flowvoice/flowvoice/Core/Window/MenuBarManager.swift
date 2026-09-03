import AppKit

@MainActor
final class MenuBarManager: NSObject {

    private var statusItem: NSStatusItem?

    private weak var controller: FlowVoiceController?

    func configure(
        controller: FlowVoiceController
    ) {
        self.controller = controller

        if statusItem != nil {
            return
        }

        let item = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
        )

        statusItem = item

        if let button = item.button {
            button.image = NSImage(
                systemSymbolName: "waveform",
                accessibilityDescription: "FlowVoice"
            )

            button.image?.isTemplate = true

            button.toolTip = "FlowVoice"
        }

        item.menu = buildMenu()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open FlowVoice",
            action: #selector(openFlowVoice),
            keyEquivalent: ""
        )

        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(
            .separator()
        )

        let listenItem = NSMenuItem(
            title: "Start Listening",
            action: #selector(startListening),
            keyEquivalent: ""
        )

        listenItem.target = self
        menu.addItem(listenItem)

        let stopItem = NSMenuItem(
            title: "Stop Listening",
            action: #selector(stopListening),
            keyEquivalent: ""
        )

        stopItem.target = self
        menu.addItem(stopItem)

        menu.addItem(
            .separator()
        )

        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )

        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(
            .separator()
        )

        let quitItem = NSMenuItem(
            title: "Quit FlowVoice",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )

        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc
    private func openFlowVoice() {
        NSApplication.shared.activate(
            ignoringOtherApps: true
        )

        if let window = NSApplication.shared.windows.first(
            where: {
                $0.canBecomeMain &&
                $0.level == .normal
            }
        ) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        NSApplication.shared.sendAction(
            Selector(("showMainWindow:")),
            to: nil,
            from: nil
        )
    }

    @objc
    private func startListening() {
        controller?.startListening()
    }

    @objc
    private func stopListening() {
        controller?.stopListening()
    }

    @objc
    private func openSettings() {
        NSApplication.shared.activate(
            ignoringOtherApps: true
        )

        NSApplication.shared.sendAction(
            Selector(("showSettingsWindow:")),
            to: nil,
            from: nil
        )
    }

    @objc
    private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

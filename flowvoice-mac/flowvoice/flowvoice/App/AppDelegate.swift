import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var floatingWindowController:
        FloatingVoiceWindowController?

    private var menuBarManager:
        MenuBarManager?

    private weak var controller:
        FlowVoiceController?

    private var shortcutIsPressed = false

    func applicationDidFinishLaunching(
        _ notification: Notification
    ) {

        FlowVoiceAppearance.apply()

        AccessibilityPermissionService
            .shared
            .requestPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {

        false
    }

    func configure(
        controller: FlowVoiceController
    ) {

        if self.controller === controller {
            return
        }

        self.controller = controller

        floatingWindowController =
            FloatingVoiceWindowController(
                controller: controller
            )

        let menuBarManager =
            MenuBarManager()

        menuBarManager.configure(
            controller: controller
        )

        self.menuBarManager =
            menuBarManager

        // MARK: - Shortcut Down

        GlobalShortcutManager.shared.onKeyDown = {
            [weak self] in

            guard let self else {
                return
            }

            // Prevent key-repeat from triggering
            // multiple show/start calls.
            guard !self.shortcutIsPressed else {
                return
            }

            self.shortcutIsPressed = true

            self.floatingWindowController?
                .show()

            self.controller?
                .startListening()
        }

        // MARK: - Shortcut Up

        GlobalShortcutManager.shared.onKeyUp = {
            [weak self] in

            guard let self else {
                return
            }

            guard self.shortcutIsPressed else {
                return
            }

            self.shortcutIsPressed = false

            self.controller?
                .stopListening()

            self.floatingWindowController?
                .hide(
                    after: 0.9
                )
        }

        GlobalShortcutManager.shared.start()
    }
}

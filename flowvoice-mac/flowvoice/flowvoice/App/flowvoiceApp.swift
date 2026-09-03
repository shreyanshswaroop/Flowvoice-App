import SwiftUI
import AppKit

@main
struct flowvoiceApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    @StateObject
    private var controller =
        FlowVoiceController()

    @StateObject
    private var authManager =
        AuthManager()

    @AppStorage(FlowVoiceAppearance.storageKey)
    private var appearanceRawValue =
        FlowVoiceAppearance.system.rawValue

    var body: some Scene {

        WindowGroup(
            "FlowVoice",
            id: "main"
        ) {

            RootView()
                .environmentObject(
                    controller
                )
                .environmentObject(
                    authManager
                )
                .preferredColorScheme(
                    selectedAppearance.colorScheme
                )
                .background(
                    FlowVoiceTheme.pageBackground
                )
                .onAppear {

                    appDelegate.configure(
                        controller: controller
                    )

                    configureMainWindow(
                        appearance: selectedAppearance
                    )
                }
                .onChange(
                    of: appearanceRawValue
                ) { _, _ in

                    applyAppearance()
                }
        }

        .defaultSize(
            width: 1320,
            height: 860
        )

        .windowStyle(
            .hiddenTitleBar
        )

        .windowResizability(
            .automatic
        )

        .commands {

            CommandGroup(
                replacing: .newItem
            ) {}
        }
    }

    // MARK: - Selected Appearance

    private var selectedAppearance: FlowVoiceAppearance {

        FlowVoiceAppearance(
            rawValue: appearanceRawValue
        ) ?? .system
    }

    // MARK: - Apply Appearance

    private func applyAppearance() {

        FlowVoiceAppearance.apply(
            selectedAppearance
        )

        DispatchQueue.main.async {

            guard let window =
                NSApplication.shared.windows.first(
                    where: {
                        $0.level == .normal
                    }
                )
            else {
                return
            }

            window.appearance =
                selectedAppearance.nsAppearance

            window.backgroundColor =
                FlowVoiceTheme.nsWindowBackground
        }
    }

    // MARK: - Window Configuration

    private func configureMainWindow(
        appearance: FlowVoiceAppearance
    ) {

        DispatchQueue.main.async {

            FlowVoiceAppearance.apply(
                appearance
            )

            guard let window =
                NSApplication.shared.windows.first(
                    where: {
                        $0.level == .normal
                    }
                )
            else {
                return
            }

            window.title =
                "FlowVoice"

            window.titleVisibility =
                .hidden

            window.titlebarAppearsTransparent =
                true

            window.styleMask.insert(
                .fullSizeContentView
            )

            window.appearance =
                appearance.nsAppearance

            window.minSize =
                NSSize(
                    width: 1050,
                    height: 700
                )

            window.backgroundColor =
                FlowVoiceTheme
                    .nsWindowBackground

            window.isOpaque =
                true

            closeDuplicateMainWindows(
                keeping: window
            )
        }
    }

    // MARK: - Single Main Window

    private func closeDuplicateMainWindows(
        keeping mainWindow: NSWindow
    ) {

        let duplicateWindows =
            NSApplication.shared.windows.filter { window in

                window !== mainWindow &&
                window.level == .normal &&
                window.isVisible
            }

        duplicateWindows.forEach { window in

            window.close()
        }

        mainWindow.makeKeyAndOrderFront(
            nil
        )
    }
}

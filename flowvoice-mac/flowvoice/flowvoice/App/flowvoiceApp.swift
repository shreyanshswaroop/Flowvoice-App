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

    private let sidebarButtonHandler =
        SidebarTitlebarButtonHandler()

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
                .preferredColorScheme(.dark)
                .environment(
                    \.colorScheme,
                    .dark
                )
                .background(
                    FlowVoiceTheme.pageBackground
                )
                .onOpenURL { url in
                    authManager.handleAuthCallback(
                        url
                    )
                }
                .onAppear {

                    appDelegate.configure(
                        controller: controller
                    )

                    configureMainWindow()
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

    // MARK: - Window Configuration

    private func configureMainWindow() {

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

            window.title =
                "FlowVoice"

            window.titleVisibility =
                .hidden

            window.titlebarAppearsTransparent =
                true

            window.styleMask.insert(
                .fullSizeContentView
            )

            NSApplication.shared.appearance =
                NSAppearance(
                    named: .darkAqua
                )

            window.appearance =
                NSAppearance(
                    named: .darkAqua
                )

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

            addSidebarTitlebarButton(
                to: window
            )

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

        mainWindow.makeKeyAndOrderFront(nil)
    }

    // MARK: - Sidebar Titlebar Button

    private func addSidebarTitlebarButton(
        to window: NSWindow
    ) {

        guard
            let zoomButton =
                window.standardWindowButton(
                    .zoomButton
                ),
            let titlebarView =
                zoomButton.superview
        else {
            return
        }

        // Prevent duplicate button
        if titlebarView.viewWithTag(9001) != nil {
            return
        }

        // MARK: Sidebar Symbol

        guard let baseImage =
            NSImage(
                systemSymbolName:
                    "sidebar.right",
                accessibilityDescription:
                    "Collapse sidebar"
            )
        else {
            return
        }

        let configuration =
            NSImage.SymbolConfiguration(
                pointSize: 18,
                weight: .medium
            )

        let image =
            baseImage.withSymbolConfiguration(
                configuration
            ) ?? baseImage

        // MARK: Button

        let button =
            NSButton(
                image: image,
                target: sidebarButtonHandler,
                action:
                    #selector(
                        SidebarTitlebarButtonHandler
                            .toggleSidebar
                    )
            )

        button.tag = 9001

        button.isBordered = false

        button.imagePosition =
            .imageOnly

        button.contentTintColor =
            .secondaryLabelColor

        // Position beside green traffic-light button
        button.frame =
            NSRect(
                x: 90,
                y: zoomButton.frame.midY - 17,
                width: 34,
                height: 34
            )

        titlebarView.addSubview(
            button
        )

        // MARK: - Hide when sidebar collapses

        NotificationCenter.default.addObserver(
            forName:
                .flowVoiceSidebarStateChanged,
            object: nil,
            queue: .main
        ) { notification in

            guard let collapsed =
                notification.object as? Bool
            else {
                return
            }

            button.isHidden =
                collapsed
        }
    }
}

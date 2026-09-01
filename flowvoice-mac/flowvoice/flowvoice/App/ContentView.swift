import SwiftUI
import AppKit
import Combine

struct ContentView: View {

    @EnvironmentObject var controller:
        FlowVoiceController

    @State private var selectedTab:
        SidebarTab = .dictation

    @State private var history:
        [DictationEntry] = []

    @State private var lastStoredTranscript =
        ""

    @State private var settingsSection:
        SettingsSection = .general

    @State private var showSettings =
        false

    @State private var showHelp =
        false

    @State private var isSidebarCollapsed =
        false

    @State private var hasLoadedHistory =
        false

    var body: some View {

        ZStack {

            HStack(spacing: 0) {

                FlowVoiceSidebar(
                    selectedTab: $selectedTab,
                    showSettings: $showSettings,
                    showHelp: $showHelp,
                    isCollapsed:
                        $isSidebarCollapsed
                )
                .frame(
                    width:
                        isSidebarCollapsed
                        ? 64
                        : 225
                )
                .background(
                    FlowVoiceTheme.sidebarBackground
                )

                Rectangle()
                    .fill(
                        FlowVoiceTheme.divider
                    )
                    .frame(width: 1)

                contentArea
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .background(
                        FlowVoiceTheme.pageBackground
                    )
            }

            if showSettings {

                settingsBackdrop

                SettingsModalView(
                    selectedSection:
                        $settingsSection
                )
                .environmentObject(
                    controller
                )
                .transition(
                    .scale(scale: 0.97)
                    .combined(with: .opacity)
                )
                .zIndex(2)
            }

            if showHelp {

                helpBackdrop

                HelpModalView { section in

                    settingsSection =
                        section

                    withAnimation(
                        .spring(
                            response: 0.32,
                            dampingFraction: 0.88
                        )
                    ) {
                        showHelp = false
                        showSettings = true
                    }
                }
                .transition(
                    .scale(scale: 0.97)
                    .combined(with: .opacity)
                )
                .zIndex(2)
            }
        }

        .task {
            guard !hasLoadedHistory else {
                return
            }

            hasLoadedHistory = true

            await loadHistory()
        }

        .animation(
            .easeInOut(duration: 0.22),
            value: isSidebarCollapsed
        )

        .onChange(
            of: isSidebarCollapsed
        ) { _, collapsed in

            NotificationCenter
                .default
                .post(
                    name:
                        .flowVoiceSidebarStateChanged,
                    object:
                        collapsed
                )
        }

        .animation(
            .spring(
                response: 0.32,
                dampingFraction: 0.88
            ),
            value: showSettings
        )

        .animation(
            .spring(
                response: 0.32,
                dampingFraction: 0.88
            ),
            value: showHelp
        )

        .onReceive(
            NotificationCenter
                .default
                .publisher(
                    for:
                        .toggleFlowVoiceSidebar
                )
        ) { _ in

            withAnimation(
                .easeInOut(duration: 0.22)
            ) {
                isSidebarCollapsed.toggle()
            }
        }

        .onReceive(
            controller
                .$displayTranscript
                .dropFirst()
        ) { transcript in

            storeTranscriptIfNeeded(
                transcript
            )
        }

        .onExitCommand {

            if showSettings {

                withAnimation(
                    .spring(
                        response: 0.28,
                        dampingFraction: 0.9
                    )
                ) {
                    showSettings = false
                }

            } else if showHelp {

                withAnimation(
                    .spring(
                        response: 0.28,
                        dampingFraction: 0.9
                    )
                ) {
                    showHelp = false
                }
            }
        }
    }

    private var settingsBackdrop:
        some View {

        ZStack {

            Color.black
                .opacity(0.13)

            Color(
                red: 0.82,
                green: 0.75,
                blue: 0.64
            )
            .opacity(0.05)
        }
        .ignoresSafeArea()
        .contentShape(
            Rectangle()
        )
        .onTapGesture {

            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.9
                )
            ) {
                showSettings = false
            }
        }
        .transition(.opacity)
        .zIndex(1)
    }

    private var helpBackdrop:
        some View {

        ZStack {

            Color.black
                .opacity(0.13)

            Color(
                red: 0.82,
                green: 0.75,
                blue: 0.64
            )
            .opacity(0.05)
        }
        .ignoresSafeArea()
        .contentShape(
            Rectangle()
        )
        .onTapGesture {

            withAnimation(
                .spring(
                    response: 0.28,
                    dampingFraction: 0.9
                )
            ) {
                showHelp = false
            }
        }
        .transition(.opacity)
        .zIndex(1)
    }

    @ViewBuilder
    private var contentArea:
        some View {

        switch selectedTab {

        case .dictation:

            DictationDashboardView(
                history: history,
                onDelete: deleteDictation
            )

        case .notetaker:

            NotetakerView()

        case .insights:
            InsightsView()

        case .analytics:
            AnalyticsView()

        case .dictionary:

            DictionaryView()

        case .snippets:

            SidebarPlaceholderView(
                title: "Snippets",
                icon: "text.quote"
            )

        case .style:

            SidebarPlaceholderView(
                title: "Style",
                icon: "textformat"
            )

        case .transforms:

            SidebarPlaceholderView(
                title: "Transforms",
                icon: "wand.and.stars"
            )

        case .scratchpad:

            SidebarPlaceholderView(
                title: "Scratchpad",
                icon: "square.and.pencil"
            )

        case .settings:

            DictationDashboardView(
                history: history,
                onDelete: deleteDictation
            )

        case .help:

            DictationDashboardView(
                history: history,
                onDelete: deleteDictation
            )
        }
    }

    // MARK: - Load Dictations

    private func loadHistory() async {

        do {

            let remoteDictations =
                try await DictationService
                    .shared
                    .fetchDictations()

            history =
                remoteDictations.map { dictation in

                    DictationEntry(
                        remoteID: dictation.id,
                        time: displayTime(
                            from: dictation.createdAt
                        ),
                        text: dictation.text
                    )
                }

            print(
                "Loaded \(history.count) dictations"
            )

        } catch {

            print(
                "Could not load dictations:",
                error
            )
        }
    }

    // MARK: - Delete Dictation

    private func deleteDictation(
        _ entry: DictationEntry
    ) {

        guard let remoteID =
            entry.remoteID
        else {

            print(
                "Dictation is still syncing. Cannot delete yet."
            )

            return
        }

        print(
            "Deleting Mongo dictation:",
            remoteID
        )

        Task {

            do {

                try await DictationService
                    .shared
                    .deleteDictation(
                        id: remoteID
                    )

                withAnimation(
                    .easeInOut(duration: 0.2)
                ) {
                    history.removeAll {
                        $0.id == entry.id
                    }
                }

                print(
                    "Deleted dictation:",
                    remoteID
                )

            } catch {

                print(
                    "Could not delete dictation:",
                    error
                )
            }
        }
    }

    // MARK: - Transcript Storage

    private func storeTranscriptIfNeeded(
        _ transcript: String
    ) {

        guard
            case .inserted =
                controller.state
        else {
            return
        }

        let cleaned =
            transcript
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard !cleaned.isEmpty else {
            return
        }

        guard
            cleaned !=
                "Hold ⌥ Space to speak"
        else {
            return
        }

        guard
            cleaned !=
                "Listening..."
        else {
            return
        }

        guard
            cleaned !=
                lastStoredTranscript
        else {
            return
        }

        lastStoredTranscript =
            cleaned

        // Temporary local row
        let localEntry =
            DictationEntry(
                time:
                    timeString(
                        for: Date()
                    ),
                text:
                    cleaned
            )

        history.insert(
            localEntry,
            at: 0
        )

        // Save to backend
        Task {

            do {

                let saved =
                    try await DictationService
                        .shared
                        .saveDictation(
                            text: cleaned
                        )

                let savedEntry =
                    DictationEntry(
                        id: localEntry.id,
                        remoteID: saved.id,
                        time: displayTime(
                            from: saved.createdAt
                        ),
                        text: saved.text
                    )

                if let index =
                    history.firstIndex(
                        where: {
                            $0.id ==
                                localEntry.id
                        }
                    ) {

                    history[index] =
                        savedEntry
                }

                print(
                    "Dictation saved with Mongo ID:",
                    saved.id
                )

            } catch {

                print(
                    "Could not save dictation:",
                    error
                )
            }
        }
    }

    // MARK: - Date Helpers

    private func displayTime(
        from isoDate: String
    ) -> String {

        let formatter =
            ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        guard let date =
            formatter.date(
                from: isoDate
            )
        else {

            print(
                "Could not parse date:",
                isoDate
            )

            return "--"
        }

        return timeString(
            for: date
        )
    }

    private func timeString(
        for date: Date
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "h:mm a"

        return formatter
            .string(
                from: date
            )
            .lowercased()
    }
}

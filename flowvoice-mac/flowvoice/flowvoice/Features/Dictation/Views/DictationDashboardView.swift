import SwiftUI

struct DictationDashboardView: View {

    @EnvironmentObject var authManager: AuthManager

    let history: [DictationEntry]
    let onDelete: (DictationEntry) -> Void

    private let pageBackground =
        FlowVoiceTheme.pageBackground

    @State private var searchText = ""
    @State private var showingSearch = false
    @FocusState private var searchFocused: Bool

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 36
            ) {

                overviewHeader

                dictationFeaturePanel

                activitySection
            }
            .frame(
                maxWidth: 940,
                alignment: .leading
            )
            .padding(.horizontal, 58)
            .padding(.top, 18)
            .padding(.bottom, 58)
        }
        .scrollIndicators(.hidden)
        .background(
            pageBackground
        )
    }

    private var dictationFeaturePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("FLOWVOICE", systemImage: "waveform")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            Text("Your voice.\nYour words.")
                .font(.system(size: 32, weight: .regular, design: .serif))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Capture a thought, draft a message,\nand keep your ideas moving.")
                .font(.system(size: 14))
                .lineSpacing(4)
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity, minHeight: 224, alignment: .leading)
        .background {
            GeometryReader { geometry in
                Image("NotetakerAbstractHero")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay {
                        LinearGradient(
                            colors: [.black.opacity(0.72), .black.opacity(0.25), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    .accessibilityHidden(true)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(FlowVoiceTheme.hairline, lineWidth: 1)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Overview

    private var overviewHeader: some View {

        VStack(
            alignment: .leading,
            spacing: 28
        ) {

            HStack(spacing: 8) {

                Image(systemName: "mic")
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )

                Text("Dictation")
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )
            }
            .foregroundStyle(
                FlowVoiceTheme.tertiaryText
            )

            VStack(
                alignment: .leading,
                spacing: 18
            ) {

                Text("\(timeBasedGreeting), \(firstName)")
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
                    .fixedSize(horizontal: false, vertical: true)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) {
                        statistics
                        Spacer(minLength: 24)
                        shortcutLabel
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        statistics
                        shortcutLabel
                    }
                }
            }
        }
    }

    private var timeBasedGreeting: String {

        let hour =
            Calendar.current.component(
                .hour,
                from: Date()
            )

        switch hour {

        case 5..<12:
            return "Good morning"

        case 12..<17:
            return "Good afternoon"

        default:
            return "Good evening"
        }
    }

    private var firstName: String {

        guard let name = authManager.user?.name,
              !name.isEmpty
        else {
            return "there"
        }

        return name
            .split(separator: " ")
            .first
            .map(String.init)
            ?? name
    }

    private var statistics: some View {
        HStack(spacing: 18) {
            statistic(value: totalWordCount, label: "words captured")
            Rectangle()
                .fill(FlowVoiceTheme.hairline)
                .frame(width: 1, height: 14)
            statistic(value: history.count, label: "dictations")
        }
        .fixedSize()
    }

    private func statistic(value: Int, label: String) -> some View {
        HStack(spacing: 5) {
            Text(value.formatted())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(FlowVoiceTheme.primaryText)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(FlowVoiceTheme.secondaryText)
        }
    }

    private var shortcutLabel: some View {
        HStack(spacing: 6) {
            Image(systemName: "keyboard")
            Text("Hold Option + Space")
        }
        .font(.system(size: 11))
        .foregroundStyle(FlowVoiceTheme.tertiaryText)
        .fixedSize()
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Spacer()
                Button {
                    showingSearch.toggle()
                    searchFocused = showingSearch
                    if !showingSearch { searchText = "" }
                } label: {
                    Image(systemName: showingSearch ? "xmark" : "magnifyingglass")
                        .frame(width: 36, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(NoteActionButtonStyle())
                .help(showingSearch ? "Close search" : "Search dictations")
                .accessibilityLabel(showingSearch ? "Close search" : "Search dictations")
            }
            if showingSearch {
                TextField("Search dictations", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .focused($searchFocused)
            }
            if filteredHistory.isEmpty {
                Label(history.isEmpty ? "No dictations yet" : "No matching dictations",
                      systemImage: history.isEmpty ? "waveform" : "magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(FlowVoiceTheme.tertiaryText)
                    .frame(maxWidth: .infinity, minHeight: 110)
            } else {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(groupedHistory, id: \.day) { group in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(dayTitle(group.day))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(FlowVoiceTheme.secondaryText)
                            ForEach(group.entries) { entry in
                                TranscriptRow(item: entry) { onDelete(entry) }
                            }
                        }
                    }
                }
            }
        }
    }

    private var filteredHistory: [DictationEntry] {
        history.filter { searchText.isEmpty || $0.text.localizedStandardContains(searchText) }
    }

    private var groupedHistory: [(day: Date?, entries: [DictationEntry])] {
        let groups = Dictionary(grouping: filteredHistory) { entry in
            entry.createdAt.map { Calendar.current.startOfDay(for: $0) }
        }
        return groups.map { day, entries in
            (day: day, entries: entries.sorted {
                ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
            })
        }.sorted { ($0.day ?? .distantPast) > ($1.day ?? .distantPast) }
    }

    private func dayTitle(_ day: Date?) -> String {
        guard let day else { return "Earlier dictations" }
        return HistoryDateFormat.day(day)
    }

    // MARK: - Word Count

    private var totalWordCount: Int {

        history.reduce(0) {
            partial,
            item in

            partial +
            item.text
                .split(
                    separator: " "
                )
                .count
        }
    }
}

import SwiftUI

struct DictionaryView: View {

    enum DictionaryTab:
        String,
        CaseIterable,
        Identifiable {

        case all = "All"
        case personal = "Personal"
        case suggested = "Suggested"
        case shared = "Shared"

        var id: String {
            rawValue
        }
    }

    enum SortOption:
        String,
        CaseIterable,
        Identifiable {

        case newest = "Newest"
        case alphabetical = "A–Z"
        case type = "Type"

        var id: String {
            rawValue
        }
    }

    @State private var entries:
        [DictionaryEntry] = []

    @State private var suggestions:
        [DictionaryEntry] = []

    @State private var selectedTab:
        DictionaryTab = .all

    @State private var sortOption:
        SortOption = .newest

    @State private var searchText =
        ""

    @State private var isLoading =
        false

    @State private var isRefreshingSuggestions =
        false

    @State private var errorMessage:
        String?

    @State private var showEditor =
        false

    @State private var editingEntry:
        DictionaryEntry?

    private let pageBackground =
        Color(
            red: 0.972,
            green: 0.962,
            blue: 0.940
        )

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 26
            ) {

                headerSection

                introCard

                tabsSection

                toolbar

                if let errorMessage {

                    errorBanner(
                        errorMessage
                    )
                }

                entriesSection
            }
            .padding(
                .horizontal,
                34
            )
            .padding(
                .top,
                30
            )
            .padding(
                .bottom,
                50
            )
        }
        .scrollIndicators(
            .hidden
        )
        .background(
            pageBackground
        )
        .task {

            await loadAll()
        }
        .sheet(
            isPresented:
                $showEditor
        ) {

            DictionaryEntryEditor(
                entry:
                    editingEntry
            ) { saved in

                handleSavedEntry(
                    saved
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection:
        some View {

        HStack(
            alignment: .top
        ) {

            VStack(
                alignment: .leading,
                spacing: 8
            ) {

                Text("Dictionary")
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 38
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        Color.black.opacity(
                            0.9
                        )
                    )

                Text(
                    "Teach FlowVoice the words, names, and replacements you use most."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 14
                    )
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.5
                    )
                )
            }

            Spacer()

            Button {

                editingEntry =
                    nil

                showEditor =
                    true

            } label: {

                HStack(
                    spacing: 7
                ) {

                    Image(
                        systemName:
                            "plus"
                    )

                    Text(
                        "Add new"
                    )
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    .white
                )
                .padding(
                    .horizontal,
                    15
                )
                .frame(
                    height: 38
                )
                .background(
                    Color.black,
                    in:
                        RoundedRectangle(
                            cornerRadius: 10,
                            style:
                                .continuous
                        )
                )
            }
            .buttonStyle(
                .plain
            )
        }
    }

    // MARK: - Intro

    private var introCard:
        some View {

        HStack(
            spacing: 18
        ) {

            Image(
                systemName:
                    "text.book.closed"
            )
            .font(
                .system(
                    size: 20,
                    weight: .medium
                )
            )
            .foregroundStyle(
                Color.purple.opacity(
                    0.72
                )
            )
            .frame(
                width: 46,
                height: 46
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 14,
                    style:
                        .continuous
                )
                .fill(
                    Color.purple.opacity(
                        0.07
                    )
                )
            )

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    "FlowVoice learns the language you use."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 14
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.78
                    )
                )

                Text(
                    "Custom words improve Deepgram recognition. Replacement rules automatically transform your final dictation before it is inserted."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.46
                    )
                )
                .lineSpacing(3)
            }

            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                Color.white.opacity(
                    0.72
                )
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                Color.white.opacity(
                    0.82
                ),
                lineWidth: 1
            )
        )
    }

    // MARK: - Tabs

    private var tabsSection:
        some View {

        HStack(
            spacing: 4
        ) {

            ForEach(
                DictionaryTab.allCases
            ) { tab in

                Button {

                    withAnimation(
                        .easeInOut(
                            duration: 0.18
                        )
                    ) {

                        selectedTab =
                            tab
                    }

                } label: {

                    Text(
                        tab.rawValue
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 11
                        )
                        .weight(
                            selectedTab == tab
                            ? .semibold
                            : .medium
                        )
                    )
                    .foregroundStyle(
                        selectedTab == tab
                        ? Color.black.opacity(
                            0.82
                        )
                        : Color.black.opacity(
                            0.42
                        )
                    )
                    .padding(
                        .horizontal,
                        14
                    )
                    .frame(
                        height: 34
                    )
                    .background(
                        Group {

                            if selectedTab == tab {

                                RoundedRectangle(
                                    cornerRadius: 9,
                                    style:
                                        .continuous
                                )
                                .fill(
                                    Color.white.opacity(
                                        0.76
                                    )
                                )
                            }
                        }
                    )
                }
                .buttonStyle(
                    .plain
                )
            }

            Spacer()
        }
    }

    // MARK: - Toolbar

    private var toolbar:
        some View {

        HStack(
            spacing: 10
        ) {

            HStack(
                spacing: 9
            ) {

                Image(
                    systemName:
                        "magnifyingglass"
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.32
                    )
                )

                TextField(
                    "Search dictionary",
                    text:
                        $searchText
                )
                .textFieldStyle(
                    .plain
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                )
            }
            .padding(
                .horizontal,
                13
            )
            .frame(
                height: 38
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 11,
                    style:
                        .continuous
                )
                .fill(
                    Color.white.opacity(
                        0.6
                    )
                )
            )

            Menu {

                ForEach(
                    SortOption.allCases
                ) { option in

                    Button(
                        option.rawValue
                    ) {

                        sortOption =
                            option
                    }
                }

            } label: {

                HStack(
                    spacing: 6
                ) {

                    Image(
                        systemName:
                            "arrow.up.arrow.down"
                    )

                    Text(
                        sortOption.rawValue
                    )
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                    .weight(.medium)
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.55
                    )
                )
                .padding(
                    .horizontal,
                    12
                )
                .frame(
                    height: 38
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 11,
                        style:
                            .continuous
                    )
                    .fill(
                        Color.white.opacity(
                            0.6
                        )
                    )
                )
            }
            .menuStyle(
                .borderlessButton
            )

            if selectedTab == .suggested {

                Button {

                    Task {
                        await refreshSuggestions()
                    }

                } label: {

                    if isRefreshingSuggestions {

                        ProgressView()
                            .controlSize(
                                .small
                            )

                    } else {

                        Image(
                            systemName:
                                "arrow.clockwise"
                        )
                    }
                }
                .buttonStyle(
                    .plain
                )
                .frame(
                    width: 38,
                    height: 38
                )
                .background(
                    RoundedRectangle(
                        cornerRadius: 11,
                        style:
                            .continuous
                    )
                    .fill(
                        Color.white.opacity(
                            0.6
                        )
                    )
                )
            }
        }
    }

    // MARK: - Entries Section

    private var entriesSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 12
        ) {

            HStack {

                Text(
                    sectionTitle
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 9
                    )
                    .weight(.semibold)
                )
                .tracking(1.4)
                .foregroundStyle(
                    Color.black.opacity(
                        0.34
                    )
                )

                Spacer()

                Text(
                    "\(displayEntries.count)"
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 10
                    )
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.32
                    )
                )
            }

            if isLoading {

                loadingView

            } else if displayEntries.isEmpty {

                emptyView

            } else {

                VStack(
                    spacing: 8
                ) {

                    ForEach(
                        displayEntries
                    ) { entry in

                        entryRow(
                            entry
                        )
                    }
                }
            }
        }
    }

    private var sectionTitle:
        String {

        switch selectedTab {

        case .all:
            return "ALL ENTRIES"

        case .personal:
            return "PERSONAL"

        case .suggested:
            return "SUGGESTED FOR YOU"

        case .shared:
            return "SHARED"
        }
    }

    private var displayEntries:
        [DictionaryEntry] {

        var result:
            [DictionaryEntry]

        switch selectedTab {

        case .all:

            result =
                entries

        case .personal:

            result =
                entries.filter {
                    $0.scope == .personal
                }

        case .suggested:

            result =
                suggestions

        case .shared:

            result =
                entries.filter {
                    $0.scope == .shared
                }
        }

        let cleanedQuery =
            searchText
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        if !cleanedQuery.isEmpty {

            result =
                result.filter { entry in

                    entry.value
                        .localizedCaseInsensitiveContains(
                            cleanedQuery
                        )
                    ||
                    (
                        entry.replacement?
                            .localizedCaseInsensitiveContains(
                                cleanedQuery
                            )
                        ?? false
                    )
                }
        }

        switch sortOption {

        case .newest:

            return result.sorted {
                $0.createdAt
                >
                $1.createdAt
            }

        case .alphabetical:

            return result.sorted {

                $0.value
                    .localizedCaseInsensitiveCompare(
                        $1.value
                    )
                ==
                .orderedAscending
            }

        case .type:

            return result.sorted {

                $0.type.rawValue
                <
                $1.type.rawValue
            }
        }
    }

    // MARK: - Entry Row

    private func entryRow(
        _ entry: DictionaryEntry
    ) -> some View {

        HStack(
            spacing: 13
        ) {

            Image(
                systemName:
                    entryIcon(
                        entry
                    )
            )
            .font(
                .system(
                    size: 13,
                    weight: .medium
                )
            )
            .foregroundStyle(
                entry.type == .replacement
                ? Color.orange.opacity(
                    0.75
                )
                : Color.purple.opacity(
                    0.68
                )
            )
            .frame(
                width: 36,
                height: 36
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style:
                        .continuous
                )
                .fill(
                    (
                        entry.type == .replacement
                        ? Color.orange
                        : Color.purple
                    )
                    .opacity(
                        0.07
                    )
                )
            )

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                if entry.type == .replacement {

                    HStack(
                        spacing: 7
                    ) {

                        Text(
                            entry.value
                        )
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 13
                            )
                            .weight(.semibold)
                        )

                        Image(
                            systemName:
                                "arrow.right"
                        )
                        .font(
                            .system(
                                size: 9
                            )
                        )
                        .foregroundStyle(
                            Color.black.opacity(
                                0.26
                            )
                        )

                        Text(
                            entry.replacement
                            ?? ""
                        )
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 13
                            )
                            .weight(.medium)
                        )
                        .foregroundStyle(
                            Color.black.opacity(
                                0.66
                            )
                        )
                    }

                } else {

                    Text(
                        entry.value
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 13
                        )
                        .weight(.semibold)
                    )
                }

                Text(
                    secondaryLabel(
                        entry
                    )
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 9
                    )
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.32
                    )
                )
            }

            Spacer()

            if entry.isSuggestion {

                Button(
                    "Add"
                ) {

                    acceptSuggestion(
                        entry
                    )
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 10
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    .white
                )
                .padding(
                    .horizontal,
                    12
                )
                .frame(
                    height: 30
                )
                .background(
                    Color.black,
                    in:
                        RoundedRectangle(
                            cornerRadius: 8,
                            style:
                                .continuous
                        )
                )
                .buttonStyle(
                    .plain
                )

                Button {

                    rejectSuggestion(
                        entry
                    )

                } label: {

                    Image(
                        systemName:
                            "xmark"
                    )
                    .font(
                        .system(
                            size: 10,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        Color.black.opacity(
                            0.34
                        )
                    )
                    .frame(
                        width: 28,
                        height: 28
                    )
                }
                .buttonStyle(
                    .plain
                )

            } else {

                Text(
                    entry.scope.displayName
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 9
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    Color.black.opacity(
                        0.34
                    )
                )

                Button {

                    editingEntry =
                        entry

                    showEditor =
                        true

                } label: {

                    Image(
                        systemName:
                            "pencil"
                    )
                    .font(
                        .system(
                            size: 11
                        )
                    )
                    .foregroundStyle(
                        Color.black.opacity(
                            0.3
                        )
                    )
                    .frame(
                        width: 28,
                        height: 28
                    )
                }
                .buttonStyle(
                    .plain
                )

                Button {

                    deleteEntry(
                        entry
                    )

                } label: {

                    Image(
                        systemName:
                            "trash"
                    )
                    .font(
                        .system(
                            size: 11
                        )
                    )
                    .foregroundStyle(
                        Color.black.opacity(
                            0.3
                        )
                    )
                    .frame(
                        width: 28,
                        height: 28
                    )
                }
                .buttonStyle(
                    .plain
                )
            }
        }
        .padding(
            .horizontal,
            14
        )
        .frame(
            minHeight: 60
        )
        .background(
            RoundedRectangle(
                cornerRadius: 16,
                style:
                    .continuous
            )
            .fill(
                Color.white.opacity(
                    0.7
                )
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 16,
                style:
                    .continuous
            )
            .stroke(
                Color.black.opacity(
                    0.04
                ),
                lineWidth: 1
            )
        )
    }

    private func entryIcon(
        _ entry: DictionaryEntry
    ) -> String {

        switch entry.type {

        case .term:
            return "textformat"

        case .replacement:
            return "arrow.left.arrow.right"
        }
    }

    private func secondaryLabel(
        _ entry: DictionaryEntry
    ) -> String {

        if entry.isSuggestion {
            return "Suggested from your recent conversations"
        }

        switch entry.type {

        case .term:
            return "Used as a Deepgram keyterm"

        case .replacement:
            return "Applied before text insertion"
        }
    }

    // MARK: - Empty

    private var emptyView:
        some View {

        VStack(
            spacing: 10
        ) {

            Image(
                systemName:
                    selectedTab == .suggested
                    ? "sparkles"
                    : "text.book.closed"
            )
            .font(
                .system(
                    size: 25,
                    weight: .light
                )
            )
            .foregroundStyle(
                Color.black.opacity(
                    0.2
                )
            )

            Text(
                emptyTitle
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 13
                )
                .weight(.medium)
            )
            .foregroundStyle(
                Color.black.opacity(
                    0.48
                )
            )

            Text(
                emptySubtitle
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 11
                )
            )
            .foregroundStyle(
                Color.black.opacity(
                    0.32
                )
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 180
        )
        .background(
            RoundedRectangle(
                cornerRadius: 18,
                style:
                    .continuous
            )
            .fill(
                Color.white.opacity(
                    0.45
                )
            )
        )
    }

    private var emptyTitle:
        String {

        if !searchText.isEmpty {
            return "No matching entries"
        }

        switch selectedTab {

        case .all:
            return "Your dictionary is empty"

        case .personal:
            return "No personal entries"

        case .suggested:
            return "No suggestions yet"

        case .shared:
            return "No shared entries"
        }
    }

    private var emptySubtitle:
        String {

        switch selectedTab {

        case .suggested:
            return "FlowVoice will surface repeated names and unusual terms from your conversations."

        case .shared:
            return "Team sharing will become active when workspace support is added."

        default:
            return "Add a custom word or replacement to get started."
        }
    }

    // MARK: - Loading

    private var loadingView:
        some View {

        VStack(
            spacing: 10
        ) {

            ProgressView()

            Text(
                "Loading dictionary..."
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 11
                )
            )
            .foregroundStyle(
                Color.black.opacity(
                    0.35
                )
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 180
        )
    }

    // MARK: - Error

    private func errorBanner(
        _ message: String
    ) -> some View {

        HStack(
            spacing: 8
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle"
            )

            Text(
                message
            )

            Spacer()
        }
        .font(
            .custom(
                "Avenir Next",
                size: 11
            )
        )
        .foregroundStyle(
            Color.red.opacity(
                0.72
            )
        )
        .padding(12)
        .background(
            RoundedRectangle(
                cornerRadius: 12,
                style:
                    .continuous
            )
            .fill(
                Color.red.opacity(
                    0.05
                )
            )
        )
    }

    // MARK: - Load

    private func loadAll()
        async {

        isLoading =
            true

        errorMessage =
            nil

        do {

            async let loadedEntries =
                DictionaryService
                    .shared
                    .fetchEntries()

            async let loadedSuggestions =
                DictionaryService
                    .shared
                    .fetchSuggestions()

            entries =
                try await loadedEntries

            suggestions =
                try await loadedSuggestions

        } catch {

            errorMessage =
                "Could not load your dictionary."

            print(
                "Dictionary load error:",
                error
            )
        }

        isLoading =
            false
    }

    // MARK: - Suggestions

    private func refreshSuggestions()
        async {

        guard
            !isRefreshingSuggestions
        else {
            return
        }

        isRefreshingSuggestions =
            true

        errorMessage =
            nil

        do {

            suggestions =
                try await DictionaryService
                    .shared
                    .fetchSuggestions()

        } catch {

            errorMessage =
                "Could not refresh suggestions."
        }

        isRefreshingSuggestions =
            false
    }

    private func acceptSuggestion(
        _ entry: DictionaryEntry
    ) {

        Task {

            do {

                let accepted =
                    try await DictionaryService
                        .shared
                        .acceptSuggestion(
                            id:
                                entry.id
                        )

                withAnimation(
                    .easeInOut(
                        duration: 0.2
                    )
                ) {

                    suggestions.removeAll {
                        $0.id == entry.id
                    }

                    entries.insert(
                        accepted,
                        at: 0
                    )
                }

            } catch {

                errorMessage =
                    "Could not add this suggestion."
            }
        }
    }

    private func rejectSuggestion(
        _ entry: DictionaryEntry
    ) {

        Task {

            do {

                try await DictionaryService
                    .shared
                    .rejectSuggestion(
                        id:
                            entry.id
                    )

                withAnimation(
                    .easeInOut(
                        duration: 0.2
                    )
                ) {

                    suggestions.removeAll {
                        $0.id == entry.id
                    }
                }

            } catch {

                errorMessage =
                    "Could not remove this suggestion."
            }
        }
    }

    // MARK: - Delete

    private func deleteEntry(
        _ entry: DictionaryEntry
    ) {

        Task {

            do {

                try await DictionaryService
                    .shared
                    .deleteEntry(
                        id:
                            entry.id
                    )

                withAnimation(
                    .easeInOut(
                        duration: 0.2
                    )
                ) {

                    entries.removeAll {
                        $0.id == entry.id
                    }
                }

            } catch {

                errorMessage =
                    "Could not delete this entry."
            }
        }
    }

    // MARK: - Saved Entry

    private func handleSavedEntry(
        _ saved: DictionaryEntry
    ) {

        if let index =
            entries.firstIndex(
                where: {
                    $0.id == saved.id
                }
            ) {

            entries[index] =
                saved

        } else {

            entries.insert(
                saved,
                at: 0
            )
        }
    }
}


// MARK: =================================================
// MARK: ENTRY EDITOR
// MARK: =================================================

private struct DictionaryEntryEditor:
    View {

    @Environment(
        \.dismiss
    )
    private var dismiss

    let entry:
        DictionaryEntry?

    let onSaved:
        (DictionaryEntry) -> Void

    @State private var type:
        DictionaryEntryType =
            .term

    @State private var value =
        ""

    @State private var replacement =
        ""

    @State private var scope:
        DictionaryScope =
            .personal

    @State private var isSaving =
        false

    @State private var errorMessage:
        String?

    private var isEditing:
        Bool {

        entry != nil
    }

    var body: some View {

        VStack(
            alignment: .leading,
            spacing: 22
        ) {

            header

            typePicker

            valueField

            if type == .replacement {

                replacementField
            }

            scopeSection

            if let errorMessage {

                Text(
                    errorMessage
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    Color.red.opacity(
                        0.75
                    )
                )
            }

            Spacer()

            buttons
        }
        .padding(26)
        .frame(
            width: 460,
            height:
                type == .replacement
                ? 440
                : 370
        )
        .background(
            Color(
                red: 0.972,
                green: 0.962,
                blue: 0.940
            )
        )
        .onAppear {

            loadEntry()
        }
    }

    private var header:
        some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(
                isEditing
                ? "Edit dictionary entry"
                : "Add to Dictionary"
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 22
                )
                .weight(.semibold)
            )

            Text(
                "Improve recognition or automatically replace text after transcription."
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 11
                )
            )
            .foregroundStyle(
                Color.black.opacity(
                    0.42
                )
            )
        }
    }

    private var typePicker:
        some View {

        Picker(
            "Type",
            selection:
                $type
        ) {

            ForEach(
                DictionaryEntryType.allCases,
                id: \.self
            ) { item in

                Text(
                    item.displayName
                )
                .tag(
                    item
                )
            }
        }
        .pickerStyle(
            .segmented
        )
    }

    private var valueField:
        some View {

        fieldSection(
            title:
                type == .term
                ? "WORD OR PHRASE"
                : "WHEN FLOWVOICE HEARS / WRITES"
        ) {

            TextField(
                type == .term
                ? "e.g. Kubernetes"
                : "e.g. btw",
                text:
                    $value
            )
            .textFieldStyle(
                .plain
            )
            .padding(
                .horizontal,
                12
            )
            .frame(
                height: 40
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style:
                        .continuous
                )
                .fill(
                    Color.white.opacity(
                        0.72
                    )
                )
            )
        }
    }

    private var replacementField:
        some View {

        fieldSection(
            title:
                "REPLACE WITH"
        ) {

            TextField(
                "e.g. by the way",
                text:
                    $replacement
            )
            .textFieldStyle(
                .plain
            )
            .padding(
                .horizontal,
                12
            )
            .frame(
                height: 40
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style:
                        .continuous
                )
                .fill(
                    Color.white.opacity(
                        0.72
                    )
                )
            )
        }
    }

    private var scopeSection:
        some View {

        fieldSection(
            title:
                "SCOPE"
        ) {

            Picker(
                "Scope",
                selection:
                    $scope
            ) {

                Text("Personal")
                    .tag(
                        DictionaryScope.personal
                    )

                Text("Shared")
                    .tag(
                        DictionaryScope.shared
                    )
            }
            .pickerStyle(
                .segmented
            )
        }
    }

    private func fieldSection<
        Content: View
    >(
        title: String,
        @ViewBuilder content:
            () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text(
                title
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 9
                )
                .weight(.semibold)
            )
            .tracking(1.2)
            .foregroundStyle(
                Color.black.opacity(
                    0.34
                )
            )

            content()
        }
    }

    private var buttons:
        some View {

        HStack {

            Spacer()

            Button(
                "Cancel"
            ) {

                dismiss()
            }
            .buttonStyle(
                .plain
            )

            Button {

                save()

            } label: {

                if isSaving {

                    ProgressView()
                        .controlSize(
                            .small
                        )
                        .frame(
                            width: 70
                        )

                } else {

                    Text(
                        isEditing
                        ? "Save"
                        : "Add"
                    )
                    .frame(
                        width: 70
                    )
                }
            }
            .buttonStyle(
                .borderedProminent
            )
            .disabled(
                !canSave
                ||
                isSaving
            )
        }
    }

    private var canSave:
        Bool {

        let cleanValue =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            !cleanValue.isEmpty
        else {
            return false
        }

        if type == .replacement {

            return !replacement
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )
                .isEmpty
        }

        return true
    }

    private func loadEntry() {

        guard let entry else {
            return
        }

        type =
            entry.type

        value =
            entry.value

        replacement =
            entry.replacement
            ?? ""

        scope =
            entry.scope
    }

    private func save() {

        guard
            canSave,
            !isSaving
        else {
            return
        }

        isSaving =
            true

        errorMessage =
            nil

        let cleanValue =
            value
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let cleanReplacement =
            replacement
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        Task {

            do {

                let saved:
                    DictionaryEntry

                if let entry {

                    saved =
                        try await DictionaryService
                            .shared
                            .updateEntry(
                                id:
                                    entry.id,
                                type:
                                    type,
                                value:
                                    cleanValue,
                                replacement:
                                    type == .replacement
                                    ? cleanReplacement
                                    : nil,
                                scope:
                                    scope
                            )

                } else {

                    saved =
                        try await DictionaryService
                            .shared
                            .createEntry(
                                type:
                                    type,
                                value:
                                    cleanValue,
                                replacement:
                                    type == .replacement
                                    ? cleanReplacement
                                    : nil,
                                scope:
                                    scope
                            )
                }

                onSaved(
                    saved
                )

                dismiss()

            } catch DictionaryServiceError.duplicate {

                errorMessage =
                    "This dictionary entry already exists."

            } catch {

                errorMessage =
                    "Could not save this entry."

                print(
                    "Dictionary save error:",
                    error
                )
            }

            isSaving =
                false
        }
    }
}

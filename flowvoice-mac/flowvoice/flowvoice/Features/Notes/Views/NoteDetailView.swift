import SwiftUI
import AppKit

struct NoteDetailView: View {
    let note: Note
    let onClose: () -> Void
    let onNoteUpdated: (Note) -> Void
    let onNoteDeleted: (Note) -> Void

    private enum DetailTab: String, CaseIterable {
        case thoughts = "My thoughts"
        case transcript = "Transcript"
        case summary = "Summary"
    }

    @State private var currentNote: Note
    @State private var selectedTab: DetailTab = .transcript
    @State private var isGeneratingSummary = false
    @State private var summaryError: String?
    @State private var didCopy = false
    @State private var isSearching = false
    @State private var searchText = ""
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteError: String?
    @State private var showNoteMenu = false
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var searchFocused: Bool
    @AppStorage private var thoughts: String

    init(note: Note, onClose: @escaping () -> Void, onNoteUpdated: @escaping (Note) -> Void, onNoteDeleted: @escaping (Note) -> Void) {
        self.note = note
        self.onClose = onClose
        self.onNoteUpdated = onNoteUpdated
        self.onNoteDeleted = onNoteDeleted
        _currentNote = State(initialValue: note)
        _thoughts = AppStorage(wrappedValue: "", "noteThoughts.\(note.id)")
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    tabs
                    Rectangle()
                        .fill(FlowVoiceTheme.divider)
                        .frame(height: 1)

                    Group {
                        switch selectedTab {
                        case .thoughts:
                            thoughtsEditor
                        case .transcript:
                            transcriptSection
                        case .summary:
                            summarySection
                        }
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: 800, alignment: .leading)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity)
            }

            bottomBar
        }
        .foregroundStyle(FlowVoiceTheme.primaryText)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FlowVoiceTheme.elevatedSurface)
        .overlayPreferenceValue(NoteMenuAnchorKey.self) { anchor in
            if showNoteMenu, let anchor {
                GeometryReader { geometry in
                    let button = geometry[anchor]
                    let menuWidth = min(220, geometry.size.width - 32)
                    ZStack(alignment: .topLeading) {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture { showNoteMenu = false }
                        noteMenu
                            .frame(width: menuWidth)
                            .offset(x: max(16, button.maxX - menuWidth), y: button.maxY + 6)
                    }
                }
            }
        }
        .alert("Delete this note?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete note", role: .destructive) { deleteNote() }
        } message: {
            Text("This permanently deletes the note. It cannot be restored from trash.")
        }
        .alert("Could not delete note", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button {
                if showNoteMenu {
                    showNoteMenu = false
                } else {
                    onClose()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .frame(width: 36, height: 36)
                    .background(FlowVoiceTheme.selectedSurface, in: RoundedRectangle(cornerRadius: 8))
            }
            .keyboardShortcut(.cancelAction)
            .help("Back to notes")
            .accessibilityLabel("Back to notes")

            Spacer()

            Button {
                showNoteMenu.toggle()
            } label: {
                Image(systemName: "ellipsis")
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
            .anchorPreference(key: NoteMenuAnchorKey.self, value: .bounds) { $0 }
            .help("Note actions")
            .accessibilityLabel("Note actions")

            ShareLink(item: "\(currentNote.title)\n\n\(selectedTabText)") {
                Label("Share", systemImage: "square.and.arrow.up")
                    .padding(.horizontal, 14)
                    .frame(height: 36)
                    .background(FlowVoiceTheme.selectedSurface, in: RoundedRectangle(cornerRadius: 8))
            }
            .help("Share note text")
        }
        .buttonStyle(NoteActionButtonStyle())
        .font(.system(size: 15, weight: .medium))
        .padding(.horizontal, 28)
        .padding(.vertical, 20)
    }

    private var noteMenu: some View {
        VStack(spacing: 0) {
            Button {
                copy(completeNoteText)
                showNoteMenu = false
            } label: {
                noteMenuLabel("Copy notes", icon: "doc.on.doc", color: FlowVoiceTheme.primaryText)
            }
            Button {} label: {
                noteMenuLabel("Send notes via email", icon: "envelope", color: FlowVoiceTheme.mutedText)
            }
            .disabled(true)

            Rectangle()
                .fill(FlowVoiceTheme.hairline)
                .frame(height: 1)
                .padding(.horizontal, 7)
                .padding(.vertical, 5)

            Button(role: .destructive) {
                showNoteMenu = false
                showDeleteConfirmation = true
            } label: {
                noteMenuLabel("Move to trash", icon: "trash", color: Color(red: 0.82, green: 0.24, blue: 0.13))
            }
            .disabled(isDeleting || isGeneratingSummary)
            .opacity(isDeleting || isGeneratingSummary ? 0.45 : 1)
        }
        .buttonStyle(NoteMenuButtonStyle())
        .padding(6)
        .background(colorScheme == .dark ? Color(nsColor: .windowBackgroundColor) : .white,
                    in: RoundedRectangle(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(FlowVoiceTheme.hairline, lineWidth: 1)
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 8)
    }

    private func noteMenuLabel(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 16)
            Text(title)
                .font(.system(size: 13))
            Spacer(minLength: 0)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 9)
        .frame(height: 30)
        .contentShape(Rectangle())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(currentNote.title.isEmpty ? "New note" : currentNote.title)
                .font(.system(size: 36, weight: .regular, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)

            Text(formattedDate)
                .font(.system(size: 15))
                .foregroundStyle(FlowVoiceTheme.secondaryText)
        }
        .padding(.top, 8)
        .padding(.bottom, 22)
    }

    private var tabs: some View {
        HStack(spacing: 26) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 14) {
                        HStack(spacing: 6) {
                            if tab == .summary {
                                Image(systemName: "sparkle")
                            }
                            Text(tab.rawValue)
                        }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(selectedTab == tab ? FlowVoiceTheme.primaryText : FlowVoiceTheme.secondaryText)

                        Rectangle()
                            .fill(selectedTab == tab ? FlowVoiceTheme.primaryText : .clear)
                            .frame(height: 2)
                    }
                    .fixedSize(horizontal: true, vertical: false)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
            }
        }
    }

    private var thoughtsEditor: some View {
        TextEditor(text: $thoughts)
            .font(.system(size: 16))
            .scrollContentBackground(.hidden)
            .padding(12)
            .frame(minHeight: 300)
            .background(FlowVoiceTheme.hoverSurface, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel("My thoughts")
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Label(formattedTimestamp(Double(currentNote.durationSeconds ?? 0)), systemImage: "clock")
                        .monospacedDigit()
                    Spacer()
                    Button {
                        isSearching.toggle()
                        if isSearching {
                            searchFocused = true
                        } else {
                            searchText = ""
                        }
                    } label: {
                        Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                            .frame(width: 30, height: 30)
                    }
                    .help(isSearching ? "Close search" : "Search transcript")
                    .accessibilityLabel(isSearching ? "Close search" : "Search transcript")

                    Button { copy(transcriptText) } label: {
                        Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                            .frame(width: 30, height: 30)
                    }
                    .help(didCopy ? "Copied" : "Copy transcript")
                    .accessibilityLabel(didCopy ? "Copied" : "Copy transcript")
                }
                .buttonStyle(NoteActionButtonStyle())
                .font(.system(size: 14))
                .foregroundStyle(FlowVoiceTheme.secondaryText)
                .padding(12)

                if isSearching {
                    TextField("Search transcript", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .focused($searchFocused)
                        .padding([.horizontal, .bottom], 12)
                }
            }
            .background(FlowVoiceTheme.hoverSurface, in: RoundedRectangle(cornerRadius: 8))

            if currentNote.segments.isEmpty {
                if matchesSearch(currentNote.transcript) {
                    transcriptBubble(currentNote.transcript.isEmpty ? "No transcript" : currentNote.transcript)
                } else {
                    noSearchResults
                }
            } else if filteredSegments.isEmpty {
                noSearchResults
            } else {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(filteredSegments.enumerated()), id: \.element.id) { index, segment in
                        let startsSpeaker = index == 0 || filteredSegments[index - 1].speaker != segment.speaker
                        if startsSpeaker {
                            HStack(spacing: 10) {
                                Text(segment.displaySpeakerName)
                                    .font(.system(size: 14, weight: .medium))
                                if let start = segment.start {
                                    Text(formattedTimestamp(start))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(FlowVoiceTheme.tertiaryText)
                                }
                            }
                            .padding(.top, index == 0 ? 0 : 18)
                            .padding(.bottom, 3)
                        }
                        transcriptBubble(segment.text)
                    }
                }
            }

            HStack(spacing: 12) {
                Rectangle().fill(FlowVoiceTheme.divider).frame(height: 1)
                Image(systemName: "checkmark")
                    .font(.system(size: 10))
                    .foregroundStyle(FlowVoiceTheme.tertiaryText)
                Rectangle().fill(FlowVoiceTheme.divider).frame(height: 1)
            }
            .accessibilityLabel("End of transcript")
            .padding(.top, 8)
        }
    }

    private func transcriptBubble(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16))
            .lineSpacing(5)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FlowVoiceTheme.hoverSurface, in: RoundedRectangle(cornerRadius: 8))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noSearchResults: some View {
        Text("No matching transcript")
            .foregroundStyle(FlowVoiceTheme.secondaryText)
            .padding(.vertical, 24)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 28) {
            if hasGeneratedSummary {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Summary").font(.system(size: 20, weight: .semibold))
                    Text(currentNote.summary ?? "")
                        .font(.system(size: 16))
                        .lineSpacing(6)
                        .textSelection(.enabled)
                }
                if !currentNote.keyPoints.isEmpty {
                    summaryList("Key points", items: currentNote.keyPoints, icon: "smallcircle.filled.circle")
                }
                if !currentNote.actionItems.isEmpty {
                    summaryList("Action items", items: currentNote.actionItems, icon: "circle")
                }
            } else {
                Text(isGeneratingSummary ? "Generating summary..." : "No summary yet")
                    .font(.system(size: 16))
                    .foregroundStyle(FlowVoiceTheme.secondaryText)
                    .padding(.vertical, 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func summaryList(_ title: String, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.system(size: 18, weight: .semibold))
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 10))
                        .foregroundStyle(FlowVoiceTheme.tertiaryText)
                        .frame(width: 12, height: 22)
                    Text(item)
                        .font(.system(size: 15))
                        .lineSpacing(5)
                        .textSelection(.enabled)
                }
            }
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            if let summaryError {
                Text(summaryError)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }

            Button {
                if hasGeneratedSummary && selectedTab != .summary {
                    selectedTab = .summary
                } else {
                    generateSummary()
                }
            } label: {
                HStack(spacing: 10) {
                    if isGeneratingSummary {
                        ProgressView().controlSize(.small)
                    } else {
                        Image(systemName: "sparkle")
                    }
                    Text(isGeneratingSummary ? "Generating summary..." : summaryButtonTitle)
                }
                .font(.system(size: 15, weight: .medium))
                .padding(.horizontal, 24)
                .frame(height: 46)
                .foregroundStyle(FlowVoiceTheme.accentButtonText)
                .background(FlowVoiceTheme.accentButton, in: Capsule())
            }
            .buttonStyle(NoteActionButtonStyle(prominent: true, cornerRadius: 100))
            .disabled(isGeneratingSummary || transcriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }

    private var summaryButtonTitle: String {
        hasGeneratedSummary ? (selectedTab == .summary ? "Regenerate summary" : "View summary") : "Generate summary"
    }

    private var hasGeneratedSummary: Bool {
        !(currentNote.summary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var filteredSegments: [NoteSpeakerSegment] {
        currentNote.segments.filter { matchesSearch($0.text) }
    }

    private func matchesSearch(_ text: String) -> Bool {
        searchText.isEmpty || text.localizedStandardContains(searchText)
    }

    private var transcriptText: String {
        guard !currentNote.segments.isEmpty else { return currentNote.transcript }
        return currentNote.segments.map { segment in
            let timestamp = segment.start.map { " [\(formattedTimestamp($0))]" } ?? ""
            return "\(segment.displaySpeakerName)\(timestamp)\n\(segment.text)"
        }.joined(separator: "\n\n")
    }

    private var summaryText: String {
        var sections = [currentNote.summary ?? ""]
        if !currentNote.keyPoints.isEmpty {
            sections.append("Key points\n" + currentNote.keyPoints.map { "- \($0)" }.joined(separator: "\n"))
        }
        if !currentNote.actionItems.isEmpty {
            sections.append("Action items\n" + currentNote.actionItems.map { "- \($0)" }.joined(separator: "\n"))
        }
        return sections.joined(separator: "\n\n")
    }

    private var selectedTabText: String {
        switch selectedTab {
        case .thoughts: return thoughts
        case .transcript: return transcriptText
        case .summary: return summaryText
        }
    }

    private var completeNoteText: String {
        var sections = [currentNote.title]
        if !thoughts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sections.append("My thoughts\n\(thoughts)")
        }
        if hasGeneratedSummary {
            sections.append("Summary\n\(summaryText)")
        }
        sections.append("Transcript\n\(transcriptText)")
        return sections.joined(separator: "\n\n")
    }

    private func deleteNote() {
        guard !isDeleting && !isGeneratingSummary else { return }
        isDeleting = true
        Task { @MainActor in
            defer { isDeleting = false }
            do {
                try await NoteService.shared.deleteNote(id: currentNote.id)
                UserDefaults.standard.removeObject(forKey: "noteThoughts.\(currentNote.id)")
                onNoteDeleted(currentNote)
                onClose()
            } catch {
                deleteError = "Please try again. Your note has not been removed from this view."
            }
        }
    }

    private func generateSummary() {
        guard !isGeneratingSummary && !isDeleting else { return }
        isGeneratingSummary = true
        summaryError = nil
        Task { @MainActor in
            defer { isGeneratingSummary = false }
            do {
                let updated = try await NoteService.shared.summarizeNote(id: currentNote.id)
                currentNote = updated
                selectedTab = .summary
                onNoteUpdated(updated)
            } catch {
                summaryError = "Could not generate summary. Please try again."
            }
        }
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            didCopy = false
        }
    }

    private func formattedTimestamp(_ seconds: Double) -> String {
        let total = max(0, Int(seconds))
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var formattedDate: String {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = parser.date(from: currentNote.createdAt)
        if date == nil {
            parser.formatOptions = [.withInternetDateTime]
            date = parser.date(from: currentNote.createdAt)
        }
        guard let date else { return currentNote.createdAt }
        let output = DateFormatter()
        output.timeStyle = .short
        if Calendar.current.isDateInToday(date) {
            return "\(output.string(from: date)) today"
        }
        output.dateStyle = .medium
        return output.string(from: date)
    }
}

struct NoteMenuAnchorKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? { nil }

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}

struct NoteMenuButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        MenuRow(configuration: configuration)
    }

    private struct MenuRow: View {
        let configuration: ButtonStyle.Configuration
        @State private var isHovered = false
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .background(isEnabled && (isHovered || configuration.isPressed)
                            ? FlowVoiceTheme.hoverSurface : .clear,
                            in: RoundedRectangle(cornerRadius: 6))
                .onHover { isHovered = $0 }
        }
    }
}

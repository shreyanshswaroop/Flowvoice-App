import SwiftUI

struct InsightsView: View {
    @State private var insights: InsightsResponse?
    @State private var selectedTab = InsightTab.usage
    @State private var isLoading = false
    @State private var isGenerating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerSection
            tabBar

            if isLoading && insights == nil {
                loadingView
            } else {
                if let errorMessage {
                    errorCard(message: errorMessage)
                }

                switch selectedTab {
                case .usage:
                    usageDashboard
                case .notetaker:
                    notetakerDashboard
                }
            }
        }
        .padding(.horizontal, 42)
        .padding(.top, 32)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(FlowVoiceTheme.pageBackground)
        .task {
            await loadInsights()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .top) {
            Text("Insights")
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundStyle(FlowVoiceTheme.primaryText)

            Spacer()

            Button {
                generateInsights()
            } label: {
                ZStack {
                    Circle()
                        .fill(FlowVoiceTheme.surface)
                        .overlay {
                            Circle()
                                .stroke(FlowVoiceTheme.hairline, lineWidth: 1)
                        }
                        .frame(width: 52, height: 52)

                    Circle()
                        .strokeBorder(
                            FlowVoiceTheme.primaryText.opacity(0.34),
                            style: StrokeStyle(lineWidth: 2, dash: [5, 5])
                        )
                        .frame(width: 42, height: 42)

                    if isGenerating {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(FlowVoiceTheme.primaryText)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isGenerating)
            .help(hasGeneratedInsights ? "Refresh insights" : "Generate insights")
        }
    }

    private var tabBar: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 28) {
                ForEach(InsightTab.allCases) { tab in
                    Button {
                        withAnimation(.easeOut(duration: 0.16)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 11) {
                            Text(tab.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(selectedTab == tab ? FlowVoiceTheme.primaryText : FlowVoiceTheme.secondaryText)

                            Rectangle()
                                .fill(selectedTab == tab ? FlowVoiceTheme.primaryText : Color.clear)
                                .frame(width: tab.indicatorWidth, height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            }

            Rectangle()
                .fill(FlowVoiceTheme.divider)
                .frame(height: 1)
        }
    }

    private var usageDashboard: some View {
        GeometryReader { geometry in
            let topHeight: CGFloat = 168
            let lowerHeight = max(220, geometry.size.height - topHeight - 18)

            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    wordsPerMinuteCard
                        .frame(maxWidth: .infinity, minHeight: topHeight, maxHeight: topHeight)

                    timeSavedCard
                        .frame(maxWidth: .infinity, minHeight: topHeight, maxHeight: topHeight)

                    totalWordsCard
                        .frame(maxWidth: .infinity, minHeight: topHeight, maxHeight: topHeight)
                }
                .frame(height: topHeight)

                HStack(alignment: .top, spacing: 18) {
                    whereYouDictateCard
                        .frame(maxWidth: .infinity)

                    usageStreakCard
                        .frame(maxWidth: .infinity)
                }
                .frame(height: lowerHeight)
            }
        }
    }

    private var notetakerDashboard: some View {
        GeometryReader { geometry in
            let topHeight: CGFloat = 168
            let lowerHeight = max(230, geometry.size.height - topHeight - 18)

            VStack(spacing: 18) {
                HStack(spacing: 18) {
                    notetakerMetricCard(
                        value: "\(totalMeetings)",
                        label: "TOTAL MEETINGS",
                        detail: "Captured in FlowVoice"
                    )
                    .frame(maxWidth: .infinity, minHeight: topHeight, maxHeight: topHeight)

                    notetakerMetricCard(
                        value: meetingTime,
                        label: "MEETING TIME",
                        detail: "Recorded so far"
                    )
                    .frame(maxWidth: .infinity, minHeight: topHeight, maxHeight: topHeight)

                    notetakerMetricCard(
                        value: "\(actionItemCount)",
                        label: "ACTION ITEMS",
                        detail: "Found across meetings"
                    )
                    .frame(maxWidth: .infinity, minHeight: topHeight, maxHeight: topHeight)
                }
                .frame(height: topHeight)

                HStack(alignment: .top, spacing: 18) {
                    meetingActivityCard
                        .frame(maxWidth: .infinity)

                    VStack(spacing: 18) {
                        taskStatusCard
                        meetingIntelligenceCard
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(height: lowerHeight)
            }
        }
    }

    private var wordsPerMinuteCard: some View {
        metricShell {
            VStack(alignment: .leading, spacing: 8) {
                Text("\(estimatedWPM)")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(FlowVoiceTheme.primaryText)

                Text("WORDS PER MINUTE")
                    .metricLabel()

                ZStack(alignment: .bottom) {
                    ArcShape()
                        .stroke(FlowVoiceTheme.selectedSurface, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(height: 62)

                    ArcShape(progress: min(max(Double(estimatedWPM) / 200, 0.08), 1))
                        .stroke(FlowVoiceTheme.primaryText.opacity(0.72), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                        .frame(height: 62)

                    VStack(spacing: 2) {
                        Text("Top")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(FlowVoiceTheme.tertiaryText)

                        Text("\(wpmRank)%")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FlowVoiceTheme.primaryText)
                    }
                    .padding(.bottom, 2)
                }
                .padding(.top, 3)
            }
        }
    }

    private var timeSavedCard: some View {
        metricShell {
            VStack(alignment: .leading, spacing: 16) {
                Text(timeSaved)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(FlowVoiceTheme.primaryText)

                Text("TIME SAVED")
                    .metricLabel()

                Rectangle()
                    .fill(FlowVoiceTheme.divider)
                    .frame(height: 1)

                Text("Compared with typing")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(FlowVoiceTheme.primaryText)
            }
        }
    }

    private var totalWordsCard: some View {
        metricShell {
            VStack(alignment: .leading, spacing: 16) {
                Text("\(totalWordCount)")
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(FlowVoiceTheme.primaryText)

                Text("TOTAL WORDS DICTATED")
                    .metricLabel()

                Rectangle()
                    .fill(FlowVoiceTheme.divider)
                    .frame(height: 1)

                HStack(spacing: 10) {
                    Image(systemName: "desktopcomputer")
                        .font(.system(size: 16, weight: .medium))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Desktop")
                            .font(.system(size: 15, weight: .medium))

                        Text("\(totalWordCount) words")
                            .font(.system(size: 13))
                            .foregroundStyle(FlowVoiceTheme.secondaryText)
                    }

                    Spacer()
                }
                .foregroundStyle(FlowVoiceTheme.primaryText)
            }
        }
    }

    private var whereYouDictateCard: some View {
        insightPanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Where you dictate")
                        .font(.system(size: 25, weight: .regular, design: .serif))
                        .foregroundStyle(FlowVoiceTheme.primaryText)

                    Spacer()

                    Text("TOTAL PLACES | \(usageRows.count)")
                        .metricLabel()
                }

                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    ForEach(usageRows) { row in
                        usageRow(row)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }

    private var usageStreakCard: some View {
        insightPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(usageStreakDays) day streak")
                        .font(.system(size: 25, weight: .regular, design: .serif))
                        .foregroundStyle(FlowVoiceTheme.primaryText)

                    Spacer()

                    Text("USAGE STREAK")
                        .metricLabel()
                }

                HStack {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(FlowVoiceTheme.mutedText)

                    Spacer()

                    ForEach(["May", "Jun", "Jul", "Aug", "Sep"], id: \.self) { month in
                        Text(month)
                            .font(.system(size: 12))
                            .foregroundStyle(FlowVoiceTheme.tertiaryText)
                            .frame(maxWidth: .infinity)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(FlowVoiceTheme.mutedText)
                }

                Spacer(minLength: 0)

                streakGrid

                HStack(spacing: 8) {
                    Text("More")
                        .font(.system(size: 12))
                        .foregroundStyle(FlowVoiceTheme.secondaryText)

                    ForEach(0..<4, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(streakTone(index))
                            .frame(width: 18, height: 18)
                    }

                    Text("Less")
                        .font(.system(size: 12))
                        .foregroundStyle(FlowVoiceTheme.secondaryText)

                    Spacer()

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(FlowVoiceTheme.primaryText.opacity(0.65), lineWidth: 1)
                        .frame(width: 22, height: 22)

                    Text("Current streak")
                        .font(.system(size: 12))
                        .foregroundStyle(FlowVoiceTheme.secondaryText)
                }
            }
        }
    }

    private var meetingActivityCard: some View {
        insightPanel {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Meeting activity")
                        .font(.system(size: 25, weight: .regular, design: .serif))
                        .foregroundStyle(FlowVoiceTheme.primaryText)

                    Spacer()

                    Text("LAST 5 MONTHS")
                        .metricLabel()
                }

                Spacer(minLength: 0)

                meetingActivityGrid

                Text("Activity is based on captured meetings in this workspace.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FlowVoiceTheme.secondaryText)
            }
        }
    }

    private var taskStatusCard: some View {
        insightPanel(minHeight: 116) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Tasks")
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundStyle(FlowVoiceTheme.primaryText)

                HStack(spacing: 12) {
                    taskPill(title: "Completed", value: completedTasks)
                    taskPill(title: "Open", value: openTasks)
                    taskPill(title: "Overdue", value: overdueTasks)
                }
            }
        }
    }

    private var meetingIntelligenceCard: some View {
        insightPanel(minHeight: 126) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Meeting intelligence")
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundStyle(FlowVoiceTheme.primaryText)

                    Spacer()

                    Image(systemName: "sparkles")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(FlowVoiceTheme.tertiaryText)
                }

                Text(meetingIntelligenceText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(FlowVoiceTheme.secondaryText)
                    .lineSpacing(3)
                    .lineLimit(3)
            }
        }
    }

    private func notetakerMetricCard(value: String, label: String, detail: String) -> some View {
        metricShell {
            VStack(alignment: .leading, spacing: 16) {
                Text(value)
                    .font(.system(size: 30, weight: .regular, design: .serif))
                    .foregroundStyle(FlowVoiceTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text(label)
                    .metricLabel()

                Rectangle()
                    .fill(FlowVoiceTheme.divider)
                    .frame(height: 1)

                Text(detail)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(FlowVoiceTheme.primaryText)
            }
        }
    }

    private func usageRow(_ row: UsageRow) -> some View {
            HStack(spacing: 12) {
            Image(systemName: row.icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(FlowVoiceTheme.primaryText)
                .frame(width: 24)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(FlowVoiceTheme.selectedSurface)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(row.isPrimary ? FlowVoiceTheme.primaryText.opacity(0.78) : FlowVoiceTheme.primaryText.opacity(0.38))
                        .frame(width: max(44, geometry.size.width * row.percent))

                    Text("\(Int(row.percent * 100))%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(row.isPrimary ? FlowVoiceTheme.accentButtonText : FlowVoiceTheme.primaryText)
                        .padding(.leading, 18)
                }
            }
            .frame(height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(row.label)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(FlowVoiceTheme.primaryText)
                    .lineLimit(1)

                if !row.detail.isEmpty {
                    Text(row.detail)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(FlowVoiceTheme.tertiaryText)
                        .lineLimit(1)
                }
            }
            .frame(width: 150, alignment: .leading)
        }
    }

    private var streakGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10))
                        .foregroundStyle(FlowVoiceTheme.tertiaryText)
                        .frame(height: 11)
                }
            }

            LazyHGrid(rows: Array(repeating: GridItem(.fixed(11), spacing: 6), count: 7), spacing: 6) {
                ForEach(0..<56, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(activityCellColor(index, days: insights?.usage.activityDays ?? []))
                        .overlay {
                            if index == 54 || index == 55 {
                                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                                    .stroke(FlowVoiceTheme.primaryText.opacity(0.7), lineWidth: 1)
                            }
                        }
                        .frame(width: 11, height: 11)
                }
            }
        }
    }

    private var meetingActivityGrid: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10))
                        .foregroundStyle(FlowVoiceTheme.tertiaryText)
                        .frame(height: 11)
                }
            }

            LazyHGrid(rows: Array(repeating: GridItem(.fixed(11), spacing: 6), count: 7), spacing: 6) {
                ForEach(0..<56, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                        .fill(activityCellColor(index, days: insights?.notetaker.meetingActivity ?? []))
                        .frame(width: 11, height: 11)
                }
            }
        }
    }

    private func taskPill(title: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(value)")
                .font(.system(size: 23, weight: .regular, design: .serif))
                .foregroundStyle(FlowVoiceTheme.primaryText)

            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(FlowVoiceTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FlowVoiceTheme.selectedSurface.opacity(0.65))
        }
    }

    private func metricShell<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FlowVoiceTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(FlowVoiceTheme.hairline, lineWidth: 1)
                    }
            }
    }

    private func insightPanel<Content: View>(
        minHeight: CGFloat = 240,
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(FlowVoiceTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(FlowVoiceTheme.hairline, lineWidth: 1)
                    }
            }
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.regular)

            Text("Loading insights...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FlowVoiceTheme.tertiaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private func errorCard(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(Color.orange.opacity(0.85))

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(FlowVoiceTheme.secondaryText)

            Spacer()

            Button("Try Again") {
                generateInsights()
            }
            .font(.system(size: 12, weight: .semibold))
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.orange.opacity(0.07), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var hasGeneratedInsights: Bool {
        guard let insights else {
            return false
        }

        return insights.generatedAt != nil || insights.notesCount > 0
    }

    private var totalWordCount: Int {
        insights?.usage.totalWordsDictated ?? 0
    }

    private var estimatedWPM: Int {
        insights?.usage.wordsPerMinute ?? 0
    }

    private var wpmRank: Int {
        guard estimatedWPM > 0 else {
            return 0
        }

        return max(1, min(99, 100 - Int(Double(estimatedWPM) / 180 * 100)))
    }

    private var timeSaved: String {
        let saved = insights?.usage.timeSavedSeconds ?? 0

        if saved < 60 {
            return "\(saved)s"
        }

        let minutes = saved / 60
        let hours = minutes / 60

        if hours == 0 {
            return "\(minutes)m"
        }

        return "\(hours)h \(minutes % 60)m"
    }

    private var usageStreakDays: Int {
        insights?.usage.usageStreakDays ?? 0
    }

    private var totalMeetings: Int {
        insights?.notetaker.totalMeetings ?? 0
    }

    private var meetingTime: String {
        let seconds = insights?.notetaker.meetingTimeSeconds ?? 0
        let minutes = seconds / 60

        if minutes < 60 {
            return "\(minutes)m"
        }

        return "\(minutes / 60)h \(minutes % 60)m"
    }

    private var actionItemCount: Int {
        insights?.notetaker.actionItems ?? 0
    }

    private var completedTasks: Int {
        insights?.notetaker.completedTasks ?? 0
    }

    private var openTasks: Int {
        insights?.notetaker.openTasks ?? 0
    }

    private var overdueTasks: Int {
        insights?.notetaker.overdueTasks ?? 0
    }

    private var meetingIntelligenceText: String {
        insights?.notetaker.meetingIntelligence
            ?? "Start capturing meetings to see useful patterns about follow-ups, tasks, and meeting quality."
    }

    private var usageRows: [UsageRow] {
        let places = insights?.usage.whereYouDictate ?? []

        if places.isEmpty {
            return [
                UsageRow(icon: "desktopcomputer", percent: 0, label: "DESKTOP", detail: "0 words", isPrimary: true),
            ]
        }

        return places.map { place in
            UsageRow(
                icon: place.label.lowercased() == "desktop" ? "desktopcomputer" : "mic",
                percent: min(max(Double(place.percentage) / 100, 0), 1),
                label: place.label.uppercased(),
                detail: "\(place.words) words",
                isPrimary: place.percentage == places.map(\.percentage).max()
            )
        }
    }

    private func activityCellColor(_ index: Int, days: [InsightsActivityDay]) -> Color {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let offset = index - 55

        guard
            let date = calendar.date(
                byAdding: .day,
                value: offset,
                to: today
            )
        else {
            return FlowVoiceTheme.selectedSurface.opacity(0.45)
        }

        let key = Self.dayKeyFormatter.string(from: date)
        let count = days.first(where: { $0.date == key })?.count ?? 0

        if count <= 0 {
            return FlowVoiceTheme.selectedSurface.opacity(0.45)
        }

        if count >= 3 {
            return FlowVoiceTheme.primaryText.opacity(0.38)
        }

        if count == 2 {
            return FlowVoiceTheme.primaryText.opacity(0.24)
        }

        return FlowVoiceTheme.primaryText.opacity(0.14)
    }

    private func streakTone(_ index: Int) -> Color {
        switch index {
        case 0:
            return FlowVoiceTheme.primaryText.opacity(0.70)
        case 1:
            return FlowVoiceTheme.primaryText.opacity(0.52)
        case 2:
            return FlowVoiceTheme.primaryText.opacity(0.34)
        default:
            return FlowVoiceTheme.primaryText.opacity(0.16)
        }
    }

    private func loadInsights() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            insights = try await InsightsService.shared.fetchInsights()
        } catch {
            print("Could not load insights:", error)
            errorMessage = "Could not load your insights."
        }
    }

    private func generateInsights() {
        guard !isGenerating else {
            return
        }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let generated = try await InsightsService.shared.generateInsights()

                withAnimation(.easeInOut(duration: 0.22)) {
                    insights = generated
                }

                print("Insights generated")
            } catch {
                errorMessage = "Could not generate insights."
                print("Could not generate insights:", error)
            }

            isGenerating = false
        }
    }

    private static let dayKeyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private enum InsightTab: String, CaseIterable, Identifiable {
    case usage
    case notetaker

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .usage:
            return "Your usage"
        case .notetaker:
            return "Note Taker"
        }
    }

    var indicatorWidth: CGFloat {
        switch self {
        case .usage:
            return 74
        case .notetaker:
            return 72
        }
    }
}

private struct UsageRow: Identifiable {
    let id = UUID()
    let icon: String
    let percent: Double
    let label: String
    var detail: String = ""
    var isPrimary = false
}

private struct ArcShape: Shape {
    var progress = 1.0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width / 2, rect.height)
        let start = Angle.degrees(180)
        let end = Angle.degrees(180 + (180 * progress))

        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}

private extension Text {
    func metricLabel() -> some View {
        self
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.4)
            .foregroundStyle(FlowVoiceTheme.secondaryText)
    }
}

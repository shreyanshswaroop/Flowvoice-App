import SwiftUI
import Charts

struct AnalyticsView: View {

    @State private var analytics:
        AnalyticsResponse?

    @State private var isLoading =
        false

    @State private var errorMessage:
        String?

    private let pageBackground =
        FlowVoiceTheme.pageBackground

    var body: some View {

        ScrollView {

            VStack(
                alignment: .leading,
                spacing: 28
            ) {

                headerSection

                if isLoading &&
                    analytics == nil {

                    loadingView

                } else {

                    overviewGrid

                    if let errorMessage {

                        errorCard(
                            errorMessage
                        )
                    }

                    activityChart

                    lowerGrid
                }
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

            await loadAnalytics()
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

                Text("Analytics")
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 38
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Text(
                    "Understand how your voice activity grows over time."
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 14
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )
            }

            Spacer()

            Button {

                Task {
                    await loadAnalytics()
                }

            } label: {

                Image(
                    systemName:
                        "arrow.clockwise"
                )
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
                .frame(
                    width: 34,
                    height: 34
                )
                .background(
                    Circle()
                        .fill(
                            FlowVoiceTheme.elevatedSurface
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Overview

    private var overviewGrid:
        some View {

        LazyVGrid(
            columns: [
                GridItem(
                    .flexible(),
                    spacing: 14
                ),
                GridItem(
                    .flexible(),
                    spacing: 14
                ),
                GridItem(
                    .flexible(),
                    spacing: 14
                ),
                GridItem(
                    .flexible(),
                    spacing: 14
                ),
            ],
            spacing: 14
        ) {

            metricCard(
                title:
                    "DICTATIONS",
                value:
                    "\(analytics?.totalDictations ?? 0)",
                icon:
                    "mic",
                subtitle:
                    "Total"
            )

            metricCard(
                title:
                    "NOTES",
                value:
                    "\(analytics?.totalNotes ?? 0)",
                icon:
                    "note.text",
                subtitle:
                    "Total"
            )

            metricCard(
                title:
                    "WORDS",
                value:
                    formattedNumber(
                        analytics?
                            .totalWords
                        ?? 0
                    ),
                icon:
                    "text.word.spacing",
                subtitle:
                    "Captured"
            )

            metricCard(
                title:
                    "SPEAKING TIME",
                value:
                    formattedTime(
                        analytics?
                            .totalSpeakingSeconds
                        ?? 0
                    ),
                icon:
                    "clock",
                subtitle:
                    "Notetaker"
            )
        }
    }

    // MARK: - Metric

    private func metricCard(
        title: String,
        value: String,
        icon: String,
        subtitle: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            Image(
                systemName:
                    icon
            )
            .font(
                .system(
                    size: 14,
                    weight: .medium
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.tertiaryText
            )
            .frame(
                width: 34,
                height: 34
            )
            .background(
                RoundedRectangle(
                    cornerRadius: 10,
                    style: .continuous
                )
                .fill(
                    FlowVoiceTheme.selectedSurface
                )
            )

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(value)
                    .font(
                        .system(
                            size: 27,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )

                Text(title)
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 9
                        )
                        .weight(.semibold)
                    )
                    .tracking(1.2)
                    .foregroundStyle(
                        FlowVoiceTheme.mutedText
                    )

                Text(subtitle)
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 10
                        )
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.tertiaryText
                    )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
        .overlay(
            RoundedRectangle(
                cornerRadius: 20,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        )
    }

    // MARK: - Activity Chart

    private var activityChart:
        some View {

        VStack(
            alignment: .leading,
            spacing: 20
        ) {

            HStack {

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text(
                        "ACTIVITY"
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 9
                        )
                        .weight(.semibold)
                    )
                    .tracking(1.5)
                    .foregroundStyle(
                        FlowVoiceTheme.mutedText
                    )

                    Text(
                        "Last 7 days"
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 20
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )
                }

                Spacer()

                Text(
                    "\(analytics?.wordsThisWeek ?? 0) words this week"
                )
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
            }

            Chart(
                analytics?
                    .dailyActivity
                ?? []
            ) { item in

                BarMark(
                    x:
                        .value(
                            "Day",
                            shortDate(
                                item.date
                            )
                        ),
                    y:
                        .value(
                            "Words",
                            item.words
                        )
                )
                .cornerRadius(5)
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
            }
            .chartYAxis {

                AxisMarks(
                    position:
                        .leading
                ) {

                    AxisGridLine()
                        .foregroundStyle(
                            FlowVoiceTheme.divider
                        )

                    AxisValueLabel()
                        .foregroundStyle(
                            FlowVoiceTheme.mutedText
                        )
                }
            }
            .chartXAxis {

                AxisMarks {

                    AxisValueLabel()
                        .foregroundStyle(
                            FlowVoiceTheme.mutedText
                        )
                }
            }
            .frame(
                height: 210
            )
        }
        .padding(22)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
    }

    // MARK: - Lower Grid

    private var lowerGrid:
        some View {

        LazyVGrid(
            columns: [
                GridItem(
                    .flexible(),
                    spacing: 16
                ),
                GridItem(
                    .flexible(),
                    spacing: 16
                ),
            ],
            spacing: 16
        ) {

            usageCard

            averagesCard
        }
    }

    // MARK: - Usage

    private var usageCard:
        some View {

        analyticsContainer(
            title:
                "USAGE SPLIT",
            icon:
                "chart.pie"
        ) {

            VStack(
                spacing: 18
            ) {

                HStack {

                    usageMetric(
                        title:
                            "Dictation",
                        percentage:
                            analytics?
                                .dictationPercentage
                            ?? 0
                    )

                    Spacer()

                    usageMetric(
                        title:
                            "Notetaker",
                        percentage:
                            analytics?
                                .notePercentage
                            ?? 0
                    )
                }

                GeometryReader {
                    proxy in

                    HStack(
                        spacing: 3
                    ) {

                        RoundedRectangle(
                            cornerRadius: 5
                        )
                        .fill(
                            FlowVoiceTheme.accentButton
                        )
                        .frame(
                            width:
                                proxy.size.width
                                *
                                CGFloat(
                                    analytics?
                                        .dictationPercentage
                                    ?? 0
                                )
                                /
                                100
                        )

                        RoundedRectangle(
                            cornerRadius: 5
                        )
                        .fill(
                            FlowVoiceTheme.selectedSurface
                        )
                    }
                }
                .frame(
                    height: 8
                )
            }
        }
    }

    private func usageMetric(
        title: String,
        percentage: Int
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 4
        ) {

            Text(
                "\(percentage)%"
            )
            .font(
                .system(
                    size: 24,
                    weight: .semibold,
                    design: .rounded
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.primaryText
            )

            Text(title)
                .font(
                    .custom(
                        "Avenir Next",
                        size: 11
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.tertiaryText
                )
        }
    }

    // MARK: - Averages

    private var averagesCard:
        some View {

        analyticsContainer(
            title:
                "AVERAGES",
            icon:
                "sum"
        ) {

            VStack(
                spacing: 14
            ) {

                averageRow(
                    title:
                        "Average note",
                    value:
                        formattedTime(
                            analytics?
                                .averageNoteSeconds
                            ?? 0
                        )
                )

                Divider()
                    .overlay(
                        FlowVoiceTheme.divider
                    )

                averageRow(
                    title:
                        "Words per note",
                    value:
                        "\(analytics?.averageWordsPerNote ?? 0)"
                )

                Divider()
                    .overlay(
                        FlowVoiceTheme.divider
                    )

                averageRow(
                    title:
                        "Words per dictation",
                    value:
                        "\(analytics?.averageWordsPerDictation ?? 0)"
                )
            }
        }
    }

    private func averageRow(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.secondaryText
                )

            Spacer()

            Text(value)
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    FlowVoiceTheme.primaryText
                )
        }
    }

    // MARK: - Container

    private func analyticsContainer<
        Content: View
    >(
        title: String,
        icon: String,
        @ViewBuilder content:
            () -> Content
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 18
        ) {

            HStack(
                spacing: 7
            ) {

                Image(
                    systemName:
                        icon
                )

                Text(title)
            }
            .font(
                .custom(
                    "Avenir Next",
                    size: 9
                )
                .weight(.semibold)
            )
            .tracking(1.4)
            .foregroundStyle(
                FlowVoiceTheme.mutedText
            )

            content()
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 150,
            alignment: .topLeading
        )
        .padding(20)
        .background(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .fill(
                FlowVoiceTheme.surface
            )
        )
    }

    // MARK: - Loading

    private var loadingView:
        some View {

        VStack(
            spacing: 12
        ) {

            ProgressView()

            Text(
                "Loading analytics..."
            )
            .font(
                .custom(
                    "Avenir Next",
                    size: 12
                )
            )
            .foregroundStyle(
                FlowVoiceTheme.tertiaryText
            )
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 300
        )
    }

    // MARK: - Error

    private func errorCard(
        _ text: String
    ) -> some View {

        Text(text)
            .font(
                .custom(
                    "Avenir Next",
                    size: 12
                )
            )
            .foregroundStyle(
                .red
            )
    }

    // MARK: - Load

    private func loadAnalytics()
        async {

        isLoading =
            true

        errorMessage =
            nil

        defer {

            isLoading =
                false
        }

        do {

            analytics =
                try await AnalyticsService
                    .shared
                    .fetchAnalytics()

        } catch {

            errorMessage =
                "Could not load analytics."

            print(
                "Could not load analytics:",
                error
            )
        }
    }

    // MARK: - Helpers

    private func formattedNumber(
        _ number: Int
    ) -> String {

        let formatter =
            NumberFormatter()

        formatter.numberStyle =
            .decimal

        return formatter.string(
            from:
                NSNumber(
                    value:
                        number
                )
        )
        ?? "\(number)"
    }

    private func formattedTime(
        _ seconds: Int
    ) -> String {

        if seconds <= 0 {
            return "0m"
        }

        let hours =
            seconds / 3600

        let minutes =
            (
                seconds % 3600
            )
            / 60

        if hours > 0 {

            return "\(hours)h \(minutes)m"
        }

        return "\(minutes)m"
    }

    private func shortDate(
        _ value: String
    ) -> String {

        let input =
            DateFormatter()

        input.dateFormat =
            "yyyy-MM-dd"

        guard let date =
            input.date(
                from:
                    value
            )
        else {

            return value
        }

        let output =
            DateFormatter()

        output.dateFormat =
            "EEE"

        return output.string(
            from:
                date
        )
    }
}

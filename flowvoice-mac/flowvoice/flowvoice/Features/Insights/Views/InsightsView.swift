import SwiftUI

struct InsightsView: View {

    @State private var insights:
        InsightsResponse?

    @State private var isLoading =
        false

    @State private var isGenerating =
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
                    insights == nil {

                    loadingView

                } else {

                    overviewGrid

                    if let errorMessage {

                        errorCard(
                            message:
                                errorMessage
                        )
                    }

                    contentGrid
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

            await loadInsights()
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

                Text("Insights")
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
                    "Turn your conversations into patterns, decisions, and next steps."
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

                generateInsights()

            } label: {

                HStack(
                    spacing: 7
                ) {

                    if isGenerating {

                        ProgressView()
                            .controlSize(
                                .small
                            )

                    } else {

                        Image(
                            systemName:
                                "sparkles"
                        )

                        Text(
                            hasGeneratedInsights
                            ? "Refresh"
                            : "Generate"
                        )
                    }
                }
                .font(
                    .custom(
                        "Avenir Next",
                        size: 12
                    )
                    .weight(.semibold)
                )
                .foregroundStyle(
                    FlowVoiceTheme.accentButtonText
                )
                .padding(
                    .horizontal,
                    14
                )
                .frame(
                    height: 38
                )
                .background(
                    FlowVoiceTheme.accentButton,
                    in:
                        RoundedRectangle(
                            cornerRadius: 10,
                            style:
                                .continuous
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(
                isGenerating
            )
        }
    }

    // MARK: - Has Generated Insights

    private var hasGeneratedInsights:
        Bool {

        guard let insights else {
            return false
        }

        if insights.generatedAt != nil {
            return true
        }

        if insights.notesCount > 0 {
            return true
        }

        return false
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
                    "NOTES",
                value:
                    "\(insights?.notesCount ?? 0)",
                icon:
                    "note.text",
                subtitle:
                    "Analyzed"
            )

            metricCard(
                title:
                    "TOPICS",
                value:
                    "\(insights?.topicsCount ?? 0)",
                icon:
                    "tag",
                subtitle:
                    "Recurring"
            )

            metricCard(
                title:
                    "ACTIONS",
                value:
                    "\(insights?.actionsCount ?? 0)",
                icon:
                    "checkmark.circle",
                subtitle:
                    "Detected"
            )

            metricCard(
                title:
                    "DECISIONS",
                value:
                    "\(insights?.decisionsCount ?? 0)",
                icon:
                    "point.3.connected.trianglepath.dotted",
                subtitle:
                    "Identified"
            )
        }
    }

    // MARK: - Metric Card

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

            HStack {

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

                Spacer()
            }

            VStack(
                alignment: .leading,
                spacing: 3
            ) {

                Text(value)
                    .font(
                        .system(
                            size: 28,
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
                    .tracking(1.3)
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

    // MARK: - Main Content

    private var contentGrid:
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

            themesCard

            aiInsightCard

            decisionsCard

            actionItemsCard
        }
    }

    // MARK: - Themes

    private var themesCard:
        some View {

        insightContainer(
            title:
                "TOP THEMES",
            icon:
                "sparkles"
        ) {

            let themes =
                insights?.themes ?? []

            if themes.isEmpty {

                emptySection(
                    text:
                        "No recurring themes yet."
                )

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {

                    ForEach(
                        themes,
                        id: \.self
                    ) { theme in

                        HStack(
                            spacing: 10
                        ) {

                            Circle()
                                .fill(
                                    Color.purple.opacity(
                                        0.55
                                    )
                                )
                                .frame(
                                    width: 5,
                                    height: 5
                                )

                            Text(
                                theme
                            )
                            .font(
                                .custom(
                                    "Avenir Next",
                                    size: 13
                                )
                                .weight(.medium)
                            )
                            .foregroundStyle(
                                FlowVoiceTheme.secondaryText
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - AI Insight

    private var aiInsightCard:
        some View {

        insightContainer(
            title:
                "AI INSIGHT",
            icon:
                "sparkles"
        ) {

            let text =
                insights?
                    .aiInsight
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                ?? ""

            if text.isEmpty {

                emptySection(
                    text:
                        "Generate insights to discover patterns across your conversations."
                )

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    Text(
                        text
                    )
                    .font(
                        .custom(
                            "Avenir Next",
                            size: 15
                        )
                        .weight(.semibold)
                    )
                    .foregroundStyle(
                        FlowVoiceTheme.primaryText
                    )
                    .lineSpacing(4)

                    if let generatedAt =
                        insights?
                            .generatedAt {

                        Text(
                            "Updated \(formattedDate(generatedAt))"
                        )
                        .font(
                            .custom(
                                "Avenir Next",
                                size: 10
                            )
                        )
                        .foregroundStyle(
                            FlowVoiceTheme.mutedText
                        )
                    }
                }
            }
        }
    }

    // MARK: - Decisions

    private var decisionsCard:
        some View {

        insightContainer(
            title:
                "RECENT DECISIONS",
            icon:
                "arrow.triangle.branch"
        ) {

            let decisions =
                insights?.decisions ?? []

            if decisions.isEmpty {

                emptySection(
                    text:
                        "No decisions detected yet."
                )

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    ForEach(
                        decisions,
                        id: \.self
                    ) { decision in

                        HStack(
                            alignment: .top,
                            spacing: 9
                        ) {

                            Image(
                                systemName:
                                    "checkmark"
                            )
                            .font(
                                .system(
                                    size: 10,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(
                                Color.green.opacity(
                                    0.75
                                )
                            )
                            .padding(
                                .top,
                                3
                            )

                            Text(
                                decision
                            )
                            .font(
                                .custom(
                                    "Avenir Next",
                                    size: 12
                                )
                            )
                            .foregroundStyle(
                                FlowVoiceTheme.secondaryText
                            )
                            .lineSpacing(3)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Items

    private var actionItemsCard:
        some View {

        insightContainer(
            title:
                "ACTION ITEMS",
            icon:
                "checklist"
        ) {

            let actionItems =
                insights?
                    .actionItems
                ?? []

            if actionItems.isEmpty {

                emptySection(
                    text:
                        "No action items detected yet."
                )

            } else {

                VStack(
                    alignment: .leading,
                    spacing: 12
                ) {

                    ForEach(
                        actionItems,
                        id: \.self
                    ) { item in

                        HStack(
                            alignment: .top,
                            spacing: 9
                        ) {

                            Image(
                                systemName:
                                    "circle"
                            )
                            .font(
                                .system(
                                    size: 10
                                )
                            )
                            .foregroundStyle(
                                FlowVoiceTheme.tertiaryText
                            )
                            .padding(
                                .top,
                                3
                            )

                            Text(
                                item
                            )
                            .font(
                                .custom(
                                    "Avenir Next",
                                    size: 12
                                )
                            )
                            .foregroundStyle(
                                FlowVoiceTheme.secondaryText
                            )
                            .lineSpacing(3)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Empty Section

    private func emptySection(
        text: String
    ) -> some View {

        Text(
            text
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
        .lineSpacing(3)
    }

    // MARK: - Container

    private func insightContainer<
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
                .font(
                    .system(
                        size: 11,
                        weight: .medium
                    )
                )

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
                .tracking(1.4)
            }
            .foregroundStyle(
                FlowVoiceTheme.mutedText
            )

            content()
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 180,
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
        .overlay(
            RoundedRectangle(
                cornerRadius: 22,
                style: .continuous
            )
            .stroke(
                FlowVoiceTheme.hairline,
                lineWidth: 1
            )
        )
        .shadow(
            color:
                .black.opacity(
                    0.025
                ),
            radius: 12,
            x: 0,
            y: 6
        )
    }

    // MARK: - Loading

    private var loadingView:
        some View {

        VStack(
            spacing: 12
        ) {

            ProgressView()
                .controlSize(
                    .regular
                )

            Text(
                "Loading insights..."
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
        message: String
    ) -> some View {

        HStack(
            spacing: 10
        ) {

            Image(
                systemName:
                    "exclamationmark.triangle"
            )
            .foregroundStyle(
                Color.orange.opacity(
                    0.8
                )
            )

            Text(
                message
            )
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

            Button(
                "Try Again"
            ) {

                generateInsights()
            }
            .font(
                .custom(
                    "Avenir Next",
                    size: 11
                )
                .weight(.semibold)
            )
            .buttonStyle(
                .plain
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(
                cornerRadius: 14,
                style: .continuous
            )
            .fill(
                Color.orange.opacity(
                    0.06
                )
            )
        )
    }

    // MARK: - Load Insights

    private func loadInsights()
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

            let response =
                try await InsightsService
                    .shared
                    .fetchInsights()

            insights =
                response

        } catch {

            print(
                "Could not load insights:",
                error
            )

            errorMessage =
                "Could not load your insights."
        }
    }

    // MARK: - Generate Insights

    private func generateInsights() {

        guard
            !isGenerating
        else {
            return
        }

        isGenerating =
            true

        errorMessage =
            nil

        Task {

            do {

                let generated =
                    try await InsightsService
                        .shared
                        .generateInsights()

                withAnimation(
                    .easeInOut(
                        duration: 0.22
                    )
                ) {

                    insights =
                        generated
                }

                print(
                    "Insights generated"
                )

            } catch {

                errorMessage =
                    "Could not generate insights."

                print(
                    "Could not generate insights:",
                    error
                )
            }

            isGenerating =
                false
        }
    }

    // MARK: - Date

    private func formattedDate(
        _ isoDate: String
    ) -> String {

        let formatter =
            ISO8601DateFormatter()

        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]

        guard let date =
            formatter.date(
                from:
                    isoDate
            )
        else {

            return ""
        }

        let output =
            DateFormatter()

        output.dateStyle =
            .medium

        output.timeStyle =
            .short

        return output.string(
            from:
                date
        )
    }
}

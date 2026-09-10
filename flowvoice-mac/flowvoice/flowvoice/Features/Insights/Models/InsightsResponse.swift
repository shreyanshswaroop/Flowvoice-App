import Foundation

struct InsightsResponse:
    Codable,
    Equatable {

    let notesCount: Int
    let topicsCount: Int
    let actionsCount: Int
    let decisionsCount: Int

    let themes: [String]
    let decisions: [String]
    let actionItems: [String]

    let aiInsight: String

    let generatedAt: String?
    let usage: InsightsUsageMetrics
    let notetaker: InsightsNotetakerMetrics

    enum CodingKeys:
        String,
        CodingKey {

        case notesCount =
            "notes_count"

        case topicsCount =
            "topics_count"

        case actionsCount =
            "actions_count"

        case decisionsCount =
            "decisions_count"

        case themes
        case decisions

        case actionItems =
            "action_items"

        case aiInsight =
            "ai_insight"

        case generatedAt =
            "generated_at"

        case usage
        case notetaker
    }
}

struct InsightsUsageMetrics:
    Codable,
    Equatable {

    let wordsPerMinute: Int
    let timeSavedSeconds: Int
    let totalWordsDictated: Int
    let whereYouDictate: [InsightsDictationPlace]
    let usageStreakDays: Int
    let activityDays: [InsightsActivityDay]

    enum CodingKeys:
        String,
        CodingKey {

        case wordsPerMinute =
            "words_per_minute"

        case timeSavedSeconds =
            "time_saved_seconds"

        case totalWordsDictated =
            "total_words_dictated"

        case whereYouDictate =
            "where_you_dictate"

        case usageStreakDays =
            "usage_streak_days"

        case activityDays =
            "activity_days"
    }
}

struct InsightsNotetakerMetrics:
    Codable,
    Equatable {

    let totalMeetings: Int
    let meetingTimeSeconds: Int
    let actionItems: Int
    let meetingActivity: [InsightsActivityDay]
    let completedTasks: Int
    let openTasks: Int
    let overdueTasks: Int
    let meetingIntelligence: String

    enum CodingKeys:
        String,
        CodingKey {

        case totalMeetings =
            "total_meetings"

        case meetingTimeSeconds =
            "meeting_time_seconds"

        case actionItems =
            "action_items"

        case meetingActivity =
            "meeting_activity"

        case completedTasks =
            "completed_tasks"

        case openTasks =
            "open_tasks"

        case overdueTasks =
            "overdue_tasks"

        case meetingIntelligence =
            "meeting_intelligence"
    }
}

struct InsightsDictationPlace:
    Codable,
    Equatable,
    Identifiable {

    let label: String
    let words: Int
    let percentage: Int

    var id: String {
        label
    }
}

struct InsightsActivityDay:
    Codable,
    Equatable,
    Identifiable {

    let date: String
    let count: Int

    var id: String {
        date
    }
}

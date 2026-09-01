import Foundation

struct AnalyticsResponse:
    Codable,
    Equatable {

    let totalDictations: Int
    let totalNotes: Int
    let totalWords: Int

    let totalSpeakingSeconds: Int

    let averageNoteSeconds: Int
    let averageWordsPerNote: Int
    let averageWordsPerDictation: Int

    let dictationWords: Int
    let noteWords: Int

    let dictationPercentage: Int
    let notePercentage: Int

    let dictationsThisWeek: Int
    let notesThisWeek: Int
    let wordsThisWeek: Int

    let dailyActivity:
        [DailyActivity]

    enum CodingKeys:
        String,
        CodingKey {

        case totalDictations =
            "total_dictations"

        case totalNotes =
            "total_notes"

        case totalWords =
            "total_words"

        case totalSpeakingSeconds =
            "total_speaking_seconds"

        case averageNoteSeconds =
            "average_note_seconds"

        case averageWordsPerNote =
            "average_words_per_note"

        case averageWordsPerDictation =
            "average_words_per_dictation"

        case dictationWords =
            "dictation_words"

        case noteWords =
            "note_words"

        case dictationPercentage =
            "dictation_percentage"

        case notePercentage =
            "note_percentage"

        case dictationsThisWeek =
            "dictations_this_week"

        case notesThisWeek =
            "notes_this_week"

        case wordsThisWeek =
            "words_this_week"

        case dailyActivity =
            "daily_activity"
    }
}


struct DailyActivity:
    Codable,
    Equatable,
    Identifiable {

    var id: String {
        date
    }

    let date: String
    let dictations: Int
    let notes: Int
    let words: Int
}

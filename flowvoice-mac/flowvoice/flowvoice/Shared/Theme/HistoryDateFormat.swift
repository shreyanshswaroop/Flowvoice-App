import Foundation

enum HistoryDateFormat {
    static func day(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        formatter.setLocalizedDateFormatFromTemplate(
            calendar.component(.year, from: date) == calendar.component(.year, from: Date())
                ? "EEE d MMM" : "EEE d MMM yyyy"
        )
        return formatter.string(from: date)
    }
}

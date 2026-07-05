import Foundation
import SwiftData
import WidgetKit

enum DataStore {
    static let appGroupID = "group.com.sunpebble.dayroll"

    static var storeURL: URL {
        let base = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
            ?? URL.applicationSupportDirectory
        return base.appending(path: "Dayroll.store")
    }

    static let container: ModelContainer = {
        let config = ModelConfiguration(url: storeURL)
        return try! ModelContainer(for: Entry.self, configurations: config)
    }()

    @MainActor
    static func upsert(day rawDay: Date = .now, mood: Mood? = nil, line: String? = nil,
                       in container: ModelContainer = DataStore.container) {
        let context = container.mainContext
        let day = Calendar.current.startOfDay(for: rawDay)
        let descriptor = FetchDescriptor<Entry>(predicate: #Predicate { $0.day == day })
        let entry = (try? context.fetch(descriptor))?.first ?? {
            let new = Entry(day: day)
            context.insert(new)
            return new
        }()
        if let mood { entry.mood = mood }
        if let line { entry.line = line }
        entry.updatedAt = .now
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    @MainActor
    static func delete(day rawDay: Date, in container: ModelContainer = DataStore.container) {
        let context = container.mainContext
        let day = Calendar.current.startOfDay(for: rawDay)
        let descriptor = FetchDescriptor<Entry>(predicate: #Predicate { $0.day == day })
        for entry in (try? context.fetch(descriptor)) ?? [] {
            context.delete(entry)
        }
        try? context.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    #if DEBUG
    @MainActor
    static func seedDemo(days: Int) {
        let context = container.mainContext
        let lines = ["Coffee with Anna.", "Shipped the widget.", "Long walk, no phone.", "Rain all day.", "Read 30 pages.", ""]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        for offset in 0..<days where offset % 7 != 3 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            context.insert(Entry(
                day: day,
                moodRaw: Mood.allCases.randomElement()!.rawValue,
                line: lines[offset % lines.count]
            ))
        }
        try? context.save()
    }
    #endif

    /// Longest run of consecutive logged days anywhere in history.
    static func longestStreak(days: [Date], calendar: Calendar = .current) -> Int {
        let logged = Set(days.map { calendar.startOfDay(for: $0) })
        var best = 0
        for day in logged {
            // only walk forward from the first day of each run
            guard !logged.contains(calendar.date(byAdding: .day, value: -1, to: day)!) else { continue }
            var cursor = day
            var count = 0
            while logged.contains(cursor) {
                count += 1
                cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
            }
            best = max(best, count)
        }
        return best
    }

    enum ExportFormat: String, CaseIterable, Identifiable {
        case text = "Plain Text"
        case markdown = "Markdown"
        case csv = "CSV"
        var id: String { rawValue }
    }

    static func export(_ entries: [Entry], as format: ExportFormat) -> String {
        let sorted = entries.sorted { $0.day < $1.day }
        switch format {
        case .text:
            return sorted.map { entry in
                let date = entry.day.formatted(.iso8601.year().month().day())
                let mood = entry.mood.map { " [\($0.rawValue)]" } ?? ""
                return "\(date)\(mood) \(entry.line)"
            }
            .joined(separator: "\n")
        case .markdown:
            return sorted.map { entry in
                let date = entry.day.formatted(.iso8601.year().month().day())
                let mood = entry.mood.map { " \($0.emoji)" } ?? ""
                return "- **\(date)**\(mood) \(entry.line)"
            }
            .joined(separator: "\n")
        case .csv:
            let rows = sorted.map { entry in
                let date = entry.day.formatted(.iso8601.year().month().day())
                let line = entry.line.contains(where: { ",\"\n".contains($0) })
                    ? "\"\(entry.line.replacingOccurrences(of: "\"", with: "\"\""))\""
                    : entry.line
                return "\(date),\(entry.mood?.rawValue ?? ""),\(line)"
            }
            return (["date,mood,line"] + rows).joined(separator: "\n")
        }
    }

    /// Consecutive days ending today, or ending yesterday if today isn't logged yet.
    static func streak(days: [Date], today: Date = .now, calendar: Calendar = .current) -> Int {
        let logged = Set(days.map { calendar.startOfDay(for: $0) })
        var cursor = calendar.startOfDay(for: today)
        if !logged.contains(cursor) {
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
            guard logged.contains(cursor) else { return 0 }
        }
        var count = 0
        while logged.contains(cursor) {
            count += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: cursor)!
        }
        return count
    }
}

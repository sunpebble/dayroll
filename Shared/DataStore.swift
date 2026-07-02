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

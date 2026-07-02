import Foundation
import SwiftData

// ponytail: one entry per day, .unique on day — drop .unique before enabling CloudKit sync
@Model
final class Entry {
    @Attribute(.unique) var day: Date
    var moodRaw: String?
    var line: String
    var updatedAt: Date

    init(day: Date, moodRaw: String? = nil, line: String = "", updatedAt: Date = .now) {
        self.day = day
        self.moodRaw = moodRaw
        self.line = line
        self.updatedAt = updatedAt
    }

    var mood: Mood? {
        get { moodRaw.flatMap(Mood.init(rawValue:)) }
        set { moodRaw = newValue?.rawValue }
    }
}

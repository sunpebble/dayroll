import XCTest
import SwiftData
@testable import Dayroll

@MainActor
final class CRUDTests: XCTestCase {
    func testUpsertEditDelete() throws {
        let container = try ModelContainer(
            for: Entry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let day = Date(timeIntervalSince1970: 1_780_000_000)

        DataStore.upsert(day: day, mood: .good, line: "first", in: container)
        DataStore.upsert(day: day, mood: .bad, line: "edited", in: container)

        var entries = try container.mainContext.fetch(FetchDescriptor<Entry>())
        XCTAssertEqual(entries.count, 1, "same-day upsert must not duplicate")
        XCTAssertEqual(entries[0].line, "edited")
        XCTAssertEqual(entries[0].mood, .bad)

        DataStore.delete(day: day.addingTimeInterval(3600), in: container)
        entries = try container.mainContext.fetch(FetchDescriptor<Entry>())
        XCTAssertTrue(entries.isEmpty, "delete must match any timestamp within the day")
    }

    func testExportFormats() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let day1 = cal.date(from: DateComponents(year: 2026, month: 7, day: 4))!
        let day2 = cal.date(from: DateComponents(year: 2026, month: 7, day: 5))!
        let entries = [
            Entry(day: day2, moodRaw: "good", line: "Quiet, \"good\" day"),
            Entry(day: day1, moodRaw: nil, line: "Fireworks"),
        ]

        let text = DataStore.export(entries, as: .text)
        XCTAssertTrue(text.hasPrefix("2026-07-04 Fireworks"), "sorted oldest first, no mood tag when unset")
        XCTAssertTrue(text.contains("[good]"))

        let markdown = DataStore.export(entries, as: .markdown)
        XCTAssertTrue(markdown.contains("- **2026-07-04** Fireworks"))
        XCTAssertTrue(markdown.contains("🙂"))

        let csv = DataStore.export(entries, as: .csv)
        let lines = csv.split(separator: "\n")
        XCTAssertEqual(lines[0], "date,mood,line")
        XCTAssertEqual(lines[1], "2026-07-04,,Fireworks")
        XCTAssertEqual(lines[2], "2026-07-05,good,\"Quiet, \"\"good\"\" day\"", "commas and quotes must be escaped")
    }
}

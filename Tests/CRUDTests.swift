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
}

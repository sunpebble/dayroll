import XCTest
@testable import Dayroll

final class StreakTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    private func day(_ offset: Int, from today: Date) -> Date {
        calendar.date(byAdding: .day, value: offset, to: today)!
    }

    func testStreak() {
        let today = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_780_000_000))

        XCTAssertEqual(DataStore.streak(days: [], today: today, calendar: calendar), 0)

        // today + 2 previous days = 3
        XCTAssertEqual(
            DataStore.streak(days: [today, day(-1, from: today), day(-2, from: today)], today: today, calendar: calendar),
            3
        )

        // not logged today, but logged yesterday: streak survives
        XCTAssertEqual(
            DataStore.streak(days: [day(-1, from: today), day(-2, from: today)], today: today, calendar: calendar),
            2
        )

        // gap two days ago breaks the streak
        XCTAssertEqual(
            DataStore.streak(days: [today, day(-2, from: today), day(-3, from: today)], today: today, calendar: calendar),
            1
        )

        // last log 2+ days ago: streak is dead
        XCTAssertEqual(DataStore.streak(days: [day(-2, from: today)], today: today, calendar: calendar), 0)

        // duplicate timestamps within the same day count once
        XCTAssertEqual(
            DataStore.streak(days: [today, today.addingTimeInterval(3600), day(-1, from: today)], today: today, calendar: calendar),
            2
        )
    }
}

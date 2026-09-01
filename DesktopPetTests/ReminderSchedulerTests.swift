import XCTest
@testable import DesktopPet

final class ReminderSchedulerTests: XCTestCase {
    func testCreatesOneCandidateForEachEventAndInterval() {
        let start = Date(timeIntervalSinceReferenceDate: 10_000)
        let event = CalendarEvent(
            id: "event-1",
            title: "Planning",
            startDate: start,
            calendarItemIdentifier: "calendar-item-1"
        )

        let candidates = ReminderScheduler.candidates(
            for: [event],
            reminderMinutes: [30, 10]
        )

        XCTAssertEqual(candidates.count, 2)
        XCTAssertEqual(candidates.map(\.minutesBefore), [30, 10])
        XCTAssertEqual(candidates[0].fireDate, start.addingTimeInterval(-30 * 60))
        XCTAssertEqual(candidates[1].fireDate, start.addingTimeInterval(-10 * 60))
    }

    func testIgnoresNonPositiveIntervals() {
        let event = CalendarEvent(
            id: "event-1",
            title: "Planning",
            startDate: Date(timeIntervalSinceReferenceDate: 10_000),
            calendarItemIdentifier: "calendar-item-1"
        )

        let candidates = ReminderScheduler.candidates(
            for: [event],
            reminderMinutes: [10, 0, -5]
        )

        XCTAssertEqual(candidates.map(\.minutesBefore), [10])
    }

    func testUsesEventIdentityStartTimeAndIntervalForDeduplicationID() {
        let start = Date(timeIntervalSinceReferenceDate: 10_000)
        let event = CalendarEvent(
            id: "event-1",
            title: "Planning",
            startDate: start,
            calendarItemIdentifier: "calendar-item-1"
        )

        let first = ReminderCandidate(event: event, minutesBefore: 30)
        let second = ReminderCandidate(event: event, minutesBefore: 10)

        XCTAssertNotEqual(first.id, second.id)
        XCTAssertTrue(first.id.contains("event-1"))
    }
}

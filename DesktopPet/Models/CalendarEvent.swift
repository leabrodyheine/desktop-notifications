import Foundation

struct CalendarEvent: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let startDate: Date
    let calendarItemIdentifier: String
}

import Foundation

struct ReminderCandidate: Identifiable, Equatable, Sendable {
    let event: CalendarEvent
    let minutesBefore: Int

    var fireDate: Date {
        event.startDate.addingTimeInterval(TimeInterval(-minutesBefore * 60))
    }

    var id: String {
        "\(event.id)|\(event.startDate.timeIntervalSinceReferenceDate)|\(minutesBefore)"
    }
}

enum ReminderScheduler {
    static func candidates(
        for events: [CalendarEvent],
        reminderMinutes: [Int]
    ) -> [ReminderCandidate] {
        events
            .flatMap { event in
                reminderMinutes
                    .filter { $0 > 0 }
                    .map { ReminderCandidate(event: event, minutesBefore: $0) }
            }
            .sorted {
                if $0.fireDate == $1.fireDate {
                    return $0.event.title < $1.event.title
                }
                return $0.fireDate < $1.fireDate
            }
    }
}

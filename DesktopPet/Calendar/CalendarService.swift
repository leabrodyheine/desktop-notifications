import EventKit

@MainActor
final class CalendarService: ObservableObject {
    @Published private(set) var calendars: [EKCalendar] = []

    private let eventStore: EKEventStore

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    func requestAccess() async throws -> Bool {
        try await eventStore.requestFullAccessToEvents()
    }

    func refreshCalendars() {
        calendars = eventStore.calendars(for: .event).sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    func events(
        from startDate: Date,
        through endDate: Date,
        selectedCalendarIDs: Set<String>
    ) -> [CalendarEvent] {
        let selectedCalendars = calendars.filter {
            selectedCalendarIDs.contains($0.calendarIdentifier)
        }
        guard !selectedCalendars.isEmpty else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: selectedCalendars
        )

        return eventStore.events(matching: predicate)
            .filter { event in
                !event.isAllDay
                    && event.status != .canceled
                    && event.attendees?.first(where: \.isCurrentUser)?.participantStatus != .declined
            }
            .map { event in
                CalendarEvent(
                    id: event.eventIdentifier ?? event.calendarItemIdentifier,
                    title: normalizedTitle(event.title),
                    startDate: event.startDate,
                    calendarItemIdentifier: event.calendarItemIdentifier
                )
            }
            .sorted { $0.startDate < $1.startDate }
    }

    private func normalizedTitle(_ title: String?) -> String {
        let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Busy" : trimmed
    }
}

import AppKit
import EventKit
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel()

    @Published private(set) var calendarAuthorization: EKAuthorizationStatus
    @Published private(set) var lastError: String?

    let settings: AppSettings
    let calendarService: CalendarService

    private let presenter = ReminderPanelController()
    private var timer: Timer?
    private var calendarObserver: NSObjectProtocol?
    private var workspaceObserver: NSObjectProtocol?
    private var deliveredReminderIDs = Set<String>()
    private var isRefreshing = false

    private init() {
        settings = AppSettings()
        calendarService = CalendarService()
        calendarAuthorization = calendarService.authorizationStatus
    }

    deinit {
        if let calendarObserver {
            NotificationCenter.default.removeObserver(calendarObserver)
        }
        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
        }
    }

    func start() {
        guard timer == nil else { return }

        calendarObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAndCheckReminders()
            }
        }

        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAndCheckReminders()
            }
        }

        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refreshAndCheckReminders()
            }
        }

        Task {
            await refreshAuthorizationAndCalendars()
            await refreshAndCheckReminders()
        }
    }

    func requestCalendarAccess() async {
        do {
            _ = try await calendarService.requestAccess()
            await refreshAuthorizationAndCalendars()
            await refreshAndCheckReminders()
        } catch {
            lastError = error.localizedDescription
            calendarAuthorization = calendarService.authorizationStatus
        }
    }

    func refreshAuthorizationAndCalendars() async {
        calendarAuthorization = calendarService.authorizationStatus
        guard calendarAuthorization == .fullAccess else { return }
        calendarService.refreshCalendars()

        if !settings.hasConfiguredCalendarSelection,
           !calendarService.calendars.isEmpty {
            settings.selectedCalendarIDs = Set(calendarService.calendars.map(\.calendarIdentifier))
        }
    }

    func refreshAndCheckReminders(now: Date = Date()) async {
        guard settings.remindersEnabled,
              calendarAuthorization == .fullAccess,
              !isRefreshing else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        let windowEnd = now.addingTimeInterval(24 * 60 * 60)
        let events = calendarService.events(
            from: now.addingTimeInterval(-5 * 60),
            through: windowEnd,
            selectedCalendarIDs: settings.selectedCalendarIDs
        )
        let candidates = ReminderScheduler.candidates(
            for: events,
            reminderMinutes: settings.reminderMinutes
        )

        let due = candidates.filter {
            $0.fireDate <= now
                && $0.fireDate > now.addingTimeInterval(-120)
                && !deliveredReminderIDs.contains($0.id)
        }
        guard let first = due.first else {
            pruneDeliveredReminders(keeping: candidates)
            return
        }

        let grouped = due.filter { abs($0.fireDate.timeIntervalSince(first.fireDate)) < 60 }
        grouped.forEach { deliveredReminderIDs.insert($0.id) }
        presenter.present(
            reminders: grouped,
            onOpen: { [weak self] reminder in
                self?.openInCalendar(reminder.event)
            }
        )
        pruneDeliveredReminders(keeping: candidates)
    }

    func previewReminder() {
        let event = CalendarEvent(
            id: "preview",
            title: "Design review",
            startDate: Date().addingTimeInterval(30 * 60),
            calendarItemIdentifier: "preview"
        )
        presenter.present(
            reminders: [ReminderCandidate(event: event, minutesBefore: 30)],
            onOpen: { _ in }
        )
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            settings.launchAtLogin = enabled
            lastError = nil
        } catch {
            settings.launchAtLogin = SMAppService.mainApp.status == .enabled
            lastError = error.localizedDescription
        }
    }

    func clearError() {
        lastError = nil
    }

    private func openInCalendar(_ event: CalendarEvent) {
        guard let url = URL(string: "calshow:\(event.startDate.timeIntervalSinceReferenceDate)") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    private func pruneDeliveredReminders(keeping candidates: [ReminderCandidate]) {
        let validIDs = Set(candidates.map(\.id))
        deliveredReminderIDs.formIntersection(validIDs)
    }
}

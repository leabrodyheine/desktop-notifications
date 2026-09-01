import Foundation

@MainActor
final class AppSettings: ObservableObject {
    private enum Key {
        static let remindersEnabled = "remindersEnabled"
        static let firstReminderMinutes = "firstReminderMinutes"
        static let secondReminderMinutes = "secondReminderMinutes"
        static let selectedCalendarIDs = "selectedCalendarIDs"
        static let hasConfiguredCalendarSelection = "hasConfiguredCalendarSelection"
        static let launchAtLogin = "launchAtLogin"
    }

    private let defaults: UserDefaults

    @Published var remindersEnabled: Bool {
        didSet { defaults.set(remindersEnabled, forKey: Key.remindersEnabled) }
    }

    @Published var firstReminderMinutes: Int {
        didSet { defaults.set(firstReminderMinutes, forKey: Key.firstReminderMinutes) }
    }

    @Published var secondReminderMinutes: Int {
        didSet { defaults.set(secondReminderMinutes, forKey: Key.secondReminderMinutes) }
    }

    @Published var selectedCalendarIDs: Set<String> {
        didSet {
            defaults.set(Array(selectedCalendarIDs), forKey: Key.selectedCalendarIDs)
            defaults.set(true, forKey: Key.hasConfiguredCalendarSelection)
            hasConfiguredCalendarSelection = true
        }
    }

    private(set) var hasConfiguredCalendarSelection: Bool

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin) }
    }

    var reminderMinutes: [Int] {
        Array(Set([firstReminderMinutes, secondReminderMinutes])).sorted(by: >)
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Key.remindersEnabled: true,
            Key.firstReminderMinutes: 30,
            Key.secondReminderMinutes: 10,
            Key.selectedCalendarIDs: [String](),
            Key.hasConfiguredCalendarSelection: false,
            Key.launchAtLogin: false
        ])

        remindersEnabled = defaults.bool(forKey: Key.remindersEnabled)
        firstReminderMinutes = defaults.integer(forKey: Key.firstReminderMinutes)
        secondReminderMinutes = defaults.integer(forKey: Key.secondReminderMinutes)
        selectedCalendarIDs = Set(defaults.stringArray(forKey: Key.selectedCalendarIDs) ?? [])
        hasConfiguredCalendarSelection = defaults.bool(forKey: Key.hasConfiguredCalendarSelection)
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
    }
}

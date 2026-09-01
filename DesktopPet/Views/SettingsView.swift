import EventKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var settings: AppSettings

    private let intervalOptions = [5, 10, 15, 20, 30, 45, 60]

    init() {
        settings = AppModel.shared.settings
    }

    var body: some View {
        Form {
            Section("Reminders") {
                Toggle("Enable calendar reminders", isOn: $settings.remindersEnabled)

                Picker("First reminder", selection: $settings.firstReminderMinutes) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes before").tag(minutes)
                    }
                }

                Picker("Second reminder", selection: $settings.secondReminderMinutes) {
                    ForEach(intervalOptions, id: \.self) { minutes in
                        Text("\(minutes) minutes before").tag(minutes)
                    }
                }

                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { settings.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    )
                )
            }

            Section("Calendars") {
                if model.calendarAuthorization == .fullAccess {
                    if model.calendarService.calendars.isEmpty {
                        Text("No calendars are available.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.calendarService.calendars, id: \.calendarIdentifier) { calendar in
                            Toggle(
                                calendar.title,
                                isOn: calendarSelectionBinding(calendar.calendarIdentifier)
                            )
                        }
                    }
                } else {
                    Button("Allow Calendar Access") {
                        Task { await model.requestCalendarAccess() }
                    }
                }
            }

            Section {
                Button("Preview reminder") {
                    model.previewReminder()
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 480, height: 520)
        .task {
            await model.refreshAuthorizationAndCalendars()
        }
    }

    private func calendarSelectionBinding(_ identifier: String) -> Binding<Bool> {
        Binding(
            get: { settings.selectedCalendarIDs.contains(identifier) },
            set: { isSelected in
                if isSelected {
                    settings.selectedCalendarIDs.insert(identifier)
                } else {
                    settings.selectedCalendarIDs.remove(identifier)
                }
            }
        )
    }
}

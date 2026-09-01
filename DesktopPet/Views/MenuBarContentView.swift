import AppKit
import EventKit
import SwiftUI

struct MenuBarContentView: View {
    @EnvironmentObject private var model: AppModel
    @ObservedObject private var settings: AppSettings

    init() {
        settings = AppModel.shared.settings
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Reminders enabled", isOn: $settings.remindersEnabled)

            Divider()

            calendarStatus

            Button("Preview reminder") {
                model.previewReminder()
            }

            SettingsLink {
                Text("Settings…")
            }

            Button("Open Calendar") {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: "/System/Applications/Calendar.app"),
                    configuration: .init()
                )
            }

            Divider()

            Button("Quit Desktop Pet") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 250)
        .alert(
            "Desktop Pet",
            isPresented: Binding(
                get: { model.lastError != nil },
                set: { if !$0 { model.clearError() } }
            )
        ) {
            Button("OK") { model.clearError() }
        } message: {
            Text(model.lastError ?? "Unknown error")
        }
    }

    @ViewBuilder
    private var calendarStatus: some View {
        switch model.calendarAuthorization {
        case .fullAccess:
            Label("Calendar connected", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .denied, .restricted:
            Label("Calendar access unavailable", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Button("Open Privacy Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                    NSWorkspace.shared.open(url)
                }
            }
        case .notDetermined, .writeOnly:
            Button("Connect Apple Calendar") {
                Task { await model.requestCalendarAccess() }
            }
        @unknown default:
            Text("Calendar status unavailable")
        }
    }
}

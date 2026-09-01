import SwiftUI

struct ReminderView: View {
    @ObservedObject var state: ReminderPresentationState
    let onDismiss: () -> Void
    let onOpen: () -> Void

    @State private var isHovering = false

    private var firstReminder: ReminderCandidate? {
        state.reminders.first
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            PetIllustration(
                kind: state.pet,
                isCallingAttention: state.isCallingAttention,
                facingLeft: state.facingLeft
            )
            reminderBubble
        }
        .padding(18)
        .frame(width: 460, height: 190, alignment: .bottom)
    }

    private var reminderBubble: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(state.reminders.count == 1 ? "COMING UP" : "EVENTS COMING UP")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.8)

                    Text(titleText)
                        .font(.title3.weight(.semibold))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Text(timingText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
            }
            .buttonStyle(.plain)

            if isHovering {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .padding(10)
                .accessibilityLabel("Dismiss reminder")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.regularMaterial)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(.white.opacity(0.5))
        }
        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
        .onHover { isHovering = $0 }
    }

    private var titleText: String {
        guard state.reminders.count == 1 else {
            let titles = state.reminders.prefix(2).map(\.event.title).joined(separator: " · ")
            let remaining = state.reminders.count - 2
            return remaining > 0 ? "\(titles) + \(remaining) more" : titles
        }
        return firstReminder?.event.title ?? "Upcoming event"
    }

    private var timingText: String {
        guard let reminder = firstReminder else { return "" }
        let time = reminder.event.startDate.formatted(date: .omitted, time: .shortened)
        return "In \(reminder.minutesBefore) minutes · \(time)"
    }
}

# Desktop Notifications

A small native macOS desktop-pet app for personal calendar reminders.

## Status

This repository is currently in the product-design stage. The brief below defines the proposed first version; implementation has not started.

## App description

The app stays hidden until an Apple Calendar event approaches. At 30 and 10 minutes before the event, an illustrated desktop pet crosses the center of the screen once while displaying the event name and time remaining in a clear reminder bubble. The reminder can be dismissed immediately or clicked to open the event in Calendar. The app works entirely offline and has no accounts, servers, analytics, or AI features.

## First-version features

- Read events from selected Apple Calendar calendars through EventKit.
- Include Google Calendar events already synchronized into Apple Calendar.
- Show reminders 30 and 10 minutes before an event by default.
- Allow both reminder intervals to be configured.
- Display the event title, start time, and time remaining.
- Animate the pet smoothly across the center of the active screen once.
- Dismiss the reminder through a hover-revealed close button.
- Open the corresponding event in Calendar when its reminder is clicked.
- Provide basic menu-bar controls and local settings.
- Restore reminder scheduling after launch, calendar changes, sleep, or restart.

## Excluded from the first version

- Manual timers and reminders
- Travel-time or preparation calculations
- Wrap-up and event-ending warnings
- Notification at the exact meeting start time
- Meeting-link detection or one-click joining
- AI conversation or generated personality
- Sound
- Network access
- Accounts, cloud synchronization, servers, or databases
- Analytics, telemetry, monetization, onboarding, and App Store distribution
- Multiple selectable pets or extensive customization

## Pet appearance and personality

- **Character concept:** Illustrated pet placeholder, to be replaced later
- **Style:** Polished illustrated sprite rather than pixel art
- **Size:** Approximately 80–110 points tall, subject to visibility testing
- **Palette:** Temporary small palette of roughly four colors
- **Personality:** Friendly, purposeful, expressive, and persistent enough to be noticed
- **Reminder bubble:** Rounded illustrated speech bubble with strong contrast and concise text
- **Sound:** None

The initial placeholder should be visually neutral and easy to replace without changing reminder behavior.

## Animations and behavioral states

The first version requires five animation states:

1. Enter from the left or right.
2. Walk across the screen.
3. Make a brief attention gesture while presenting the reminder.
4. Pause briefly during the crossing.
5. Exit through the opposite edge.

Direction, speed, pause point, and gesture may vary slightly so appearances do not feel mechanical. The entire sequence should remain short and bounded. When no reminder is active, the pet stays completely hidden.

## Core interactions

- Hover over the reminder to reveal its close button.
- Click the close button to dismiss the current appearance immediately.
- Click the reminder bubble or event content to open the event in Calendar.
- Ignore the reminder to let the pet complete one crossing and disappear.
- The pet is otherwise hidden and does not accept interaction while inactive.

Dismissal of the 30-minute appearance does not cancel the separate 10-minute reminder.

## Reminder and calendar behavior

- Default reminders occur 30 and 10 minutes before each eligible event.
- Reminder intervals are globally configurable.
- The user chooses which Apple Calendar calendars are monitored.
- Google Calendar is supported only through calendars synchronized into Apple Calendar.
- Each scheduled occurrence appears at most once.
- All-day events are ignored by default.
- Declined and cancelled events are ignored.
- The bubble displays the event title, scheduled start time, and time remaining.
- No network requests are made.
- Calendar changes update pending reminders when practical.
- Simultaneous events are combined into one crossing rather than displayed as overlapping pets.

## Menu-bar controls and settings

The menu-bar menu provides:

- Enable or pause reminders
- Monitored-calendar selection
- First reminder interval
- Second reminder interval
- Launch at login
- Preview reminder animation
- Open Calendar
- Quit

A compact native settings window is sufficient; no larger settings system is needed.

## Privacy and permissions

- Request read-only calendar access through EventKit.
- Request notification permission only if background macOS notifications are required for reliable delivery.
- Store preferences locally.
- Do not transmit event titles, times, calendar information, or settings.
- Do not use accounts, telemetry, analytics, or crash-reporting services.
- Continue operating offline using locally synchronized calendar data.

Google events appear only after Apple Calendar has synchronized them locally.

## Technical recommendation

Use Swift and SwiftUI for the menu-bar interface, settings, and general state. Use AppKit only where needed for a transparent, borderless, non-activating floating window that moves across the active display. Use EventKit to read calendars and events, UserNotifications where necessary for dependable scheduling, and local preferences for settings.

Keep reminder scheduling, calendar access, and pet presentation as three straightforward components. Avoid external dependencies unless native animation proves insufficient. The app requires no account system, server, database, telemetry, analytics, or network access.

## Important edge cases

- Calendar permission is denied or later revoked.
- No calendars are selected.
- Google Calendar has not synchronized recently.
- An event is created, moved, cancelled, or deleted after reminders are scheduled.
- Events are duplicated or recurring.
- An invitation is declined or an event lasts all day.
- The app launches after the 30-minute threshold but before the 10-minute threshold.
- The Mac is asleep when a reminder should have appeared.
- Multiple events start near the same time.
- A full-screen app is active, multiple displays are connected, or displays change.
- An event has a missing or private title.
- Calendar cannot open the exact event.
- An animation is interrupted by quitting, pausing, or dismissing.

## First-version completion checklist

- [ ] Calendar permission flow works.
- [ ] Selected calendars persist locally.
- [ ] Synchronized Google Calendar events are read through EventKit.
- [ ] Eligible events receive 30- and 10-minute reminders.
- [ ] Updated and cancelled events do not produce stale reminders.
- [ ] The pet crosses the center of the active screen once and disappears.
- [ ] Animation is smooth and includes the five required states.
- [ ] The bubble clearly shows the event title, start time, and time remaining.
- [ ] The hover close button dismisses the current appearance.
- [ ] Clicking the event opens it in Calendar.
- [ ] Simultaneous events are handled without overlapping animations.
- [ ] Pause, interval, calendar, launch-at-login, and preview controls work.
- [ ] The app recovers sensibly after sleep, restart, and permission changes.
- [ ] The app works without network access.
- [ ] No sound, AI, accounts, telemetry, or server components are present.
- [ ] Placeholder artwork can later be replaced without altering calendar logic.

## Approval gates

Do not begin implementation until the brief is explicitly approved. After approval, prepare a small step-by-step implementation plan before writing code.

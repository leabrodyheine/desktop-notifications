# Desktop Pet Implementation Plan

The product brief in `README.md` is approved. Implementation follows these small stages.

1. Create a minimal Swift/SwiftUI macOS menu-bar app and confirm it builds.
2. Add locally persisted reminder, calendar, pause, and launch-at-login settings.
3. Request EventKit access and read eligible events from selected Apple calendars.
4. Schedule deduplicated 30- and 10-minute reminder occurrences and reconcile changes after launch and wake.
5. Present reminders in a transparent AppKit panel that crosses the active display.
6. Add a replaceable illustrated placeholder, five behavioral states, dismissal, and Calendar opening.
7. Test reminder timing and eligibility, then verify permissions, sleep/wake, display, and offline behavior.

## Planned commit boundaries

1. macOS menu-bar app shell
2. local settings and controls
3. EventKit calendar access
4. reminder scheduling and tests
5. floating pet window
6. animation and reminder interactions
7. lifecycle handling and final verification

No network services, third-party dependencies, accounts, analytics, sound, AI, or server components are planned.

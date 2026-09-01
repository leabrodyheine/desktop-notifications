import AppKit
import SwiftUI

@MainActor
final class ReminderPanelController {
    private let panelSize = CGSize(width: 460, height: 190)
    private var panel: NSPanel?
    private var presentationState: ReminderPresentationState?
    private var presentationID = UUID()
    private var petRotation = Int.random(in: 0..<PetKind.allCases.count)

    func present(
        reminders: [ReminderCandidate],
        onOpen: @escaping (ReminderCandidate) -> Void
    ) {
        guard let first = reminders.first,
              let screen = activeScreen() else { return }

        dismiss()
        let currentID = UUID()
        presentationID = currentID

        let pet = PetKind.allCases[petRotation % PetKind.allCases.count]
        petRotation += 1

        let travelsLeftToRight = Bool.random()
        let state = ReminderPresentationState(
            reminders: reminders,
            pet: pet,
            facingLeft: !travelsLeftToRight
        )
        presentationState = state

        let panel = makePanel()
        self.panel = panel
        panel.contentView = NSHostingView(
            rootView: ReminderView(
                state: state,
                onDismiss: { [weak self] in self?.dismiss() },
                onOpen: { [weak self] in
                    onOpen(first)
                    self?.dismiss()
                }
            )
        )

        let visibleFrame = screen.visibleFrame
        let startX = travelsLeftToRight
            ? visibleFrame.minX - panelSize.width
            : visibleFrame.maxX
        let centerX = visibleFrame.midX - panelSize.width / 2
        let endX = travelsLeftToRight
            ? visibleFrame.maxX
            : visibleFrame.minX - panelSize.width
        let y = visibleFrame.midY - panelSize.height / 2

        panel.setFrame(NSRect(x: startX, y: y, width: panelSize.width, height: panelSize.height), display: false)
        panel.orderFrontRegardless()

        animate(panel: panel, toX: centerX, duration: 3.5) { [weak self] in
            guard let self, self.presentationID == currentID else { return }
            state.isCallingAttention = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self, self.presentationID == currentID else { return }
                state.isCallingAttention = false
                self.animate(panel: panel, toX: endX, duration: 3.5) { [weak self] in
                    guard self?.presentationID == currentID else { return }
                    self?.dismiss()
                }
            }
        }
    }

    func dismiss() {
        presentationID = UUID()
        panel?.animator().alphaValue = 0
        panel?.orderOut(nil)
        panel = nil
        presentationState = nil
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        return panel
    }

    private func animate(
        panel: NSPanel,
        toX x: CGFloat,
        duration: TimeInterval,
        completion: @escaping () -> Void
    ) {
        var frame = panel.frame
        frame.origin.x = x
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            DispatchQueue.main.async(execute: completion)
        }
    }

    private func activeScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
    }
}

@MainActor
final class ReminderPresentationState: ObservableObject {
    let reminders: [ReminderCandidate]
    let pet: PetKind
    let facingLeft: Bool
    @Published var isCallingAttention = false

    init(reminders: [ReminderCandidate], pet: PetKind = .greyCat, facingLeft: Bool = false) {
        self.reminders = reminders
        self.pet = pet
        self.facingLeft = facingLeft
    }
}

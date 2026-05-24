import Foundation
import Observation

@MainActor @Observable public final class PetStateMachine {
    public private(set) var state: PetState = .idle
    public private(set) var bubbleText: String?
    public private(set) var activeReminderKind: ReminderKind?

    private var lastInteractionAt: Date
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
        self.lastInteractionAt = now()
    }

    public func tick(preferences: PetPreferences) {
        if state == .reminding {
            return
        }

        let inactiveSeconds = now().timeIntervalSince(lastInteractionAt)
        if inactiveSeconds >= TimeInterval(preferences.sleepDelayMinutes * 60) {
            state = .sleeping
            bubbleText = nil
        }
    }

    public func handle(_ event: PetEvent) {
        switch event {
        case .clicked:
            recordInteraction()
            state = state == .sleeping ? .waking : .petting
            bubbleText = nil
        case .dragged, .controlsOpened:
            recordInteraction()
            state = state == .sleeping ? .waking : .idle
            bubbleText = nil
        case let .reminderFired(kind):
            state = .reminding
            activeReminderKind = kind
            bubbleText = kind == .water ? "喝点水吧" : "休息一下吧"
        case .dismissedReminder:
            recordInteraction()
            state = .idle
            bubbleText = nil
            activeReminderKind = nil
        case let .automaticAction(action):
            guard state == .idle else {
                return
            }

            state = action == .running ? .automaticRunning : .automaticBlink
        case .animationCompleted:
            if state == .waking || state == .petting || state == .blink || state == .automaticBlink || state == .automaticRunning {
                state = .idle
            }
        }
    }

    private func recordInteraction() {
        lastInteractionAt = now()
    }
}

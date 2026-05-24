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
        case let .dragged(direction):
            recordInteraction()
            if state == .sleeping {
                state = .waking
            } else {
                state = direction == .left ? .dragRunningLeft : .dragRunningRight
            }
            bubbleText = nil
        case .controlsOpened:
            recordInteraction()
            state = state == .sleeping ? .waking : .idle
            bubbleText = nil
        case let .reminderFired(kind):
            state = .waving
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

            switch action {
            case .blink:
                state = .automaticBlink
            case .running(.left):
                state = .automaticRunningLeft
            case .running(.right):
                state = .automaticRunningRight
            }
        case .animationCompleted:
            if state == .waving {
                state = .reminding
            } else if state == .waking ||
                state == .petting ||
                state == .blink ||
                state == .dragRunningLeft ||
                state == .dragRunningRight ||
                state == .automaticBlink ||
                state == .automaticRunningLeft ||
                state == .automaticRunningRight {
                state = .idle
            }
        }
    }

    private func recordInteraction() {
        lastInteractionAt = now()
    }
}

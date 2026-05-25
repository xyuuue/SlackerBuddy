import Foundation
import Observation

@MainActor @Observable public final class PetStateMachine {
    public private(set) var state: PetState = .idle
    public private(set) var bubbleText: String?
    public private(set) var activeReminderKind: ReminderKind?

    private static let inactivitySleepDelay: TimeInterval = 30 * 60

    private var lastInteractionAt: Date
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
        self.lastInteractionAt = now()
    }

    public func tick() {
        if state == .reminding {
            return
        }

        let inactiveSeconds = now().timeIntervalSince(lastInteractionAt)
        if inactiveSeconds >= Self.inactivitySleepDelay {
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
        case let .expressiveAction(action):
            recordInteraction()
            applyExpressiveAction(action)
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
            case let .expressive(action):
                applyExpressiveAction(action)
            }
        case .animationCompleted:
            if state == .waving {
                state = .reminding
            } else if state == .waking ||
                state == .petting ||
                state == .reviewing ||
                state == .jumping ||
                state == .failed ||
                state == .waiting ||
                state == .running ||
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

    private func applyExpressiveAction(_ action: ExpressivePetAction) {
        if state == .sleeping {
            state = .waking
            return
        }

        switch action {
        case .review:
            state = .reviewing
        case .jump:
            state = .jumping
        case .fail:
            state = .failed
        case .wait:
            state = .waiting
        case .run:
            state = .running
        }
    }
}

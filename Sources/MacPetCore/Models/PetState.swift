import Foundation

public enum PetState: Equatable, Sendable {
    case idle
    case blink
    case sleeping
    case waking
    case petting
    case reminding
    case automaticBlink
    case automaticRunning
}

public enum AutomaticPetAction: Equatable, Sendable {
    case blink
    case running
}

public enum PetEvent: Equatable, Sendable {
    case clicked
    case dragged
    case controlsOpened
    case reminderFired(ReminderKind)
    case dismissedReminder
    case automaticAction(AutomaticPetAction)
    case animationCompleted
}

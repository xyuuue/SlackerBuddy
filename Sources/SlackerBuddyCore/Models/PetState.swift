import Foundation

public enum PetState: Equatable, Sendable {
    case idle
    case blink
    case sleeping
    case waking
    case petting
    case reminding
    case waving
    case dragRunningLeft
    case dragRunningRight
    case automaticBlink
    case automaticRunningLeft
    case automaticRunningRight
}

public enum PetMovementDirection: Equatable, Sendable {
    case left
    case right
}

public enum AutomaticPetAction: Equatable, Sendable {
    case blink
    case running(PetMovementDirection)
}

public enum PetEvent: Equatable, Sendable {
    case clicked
    case dragged(PetMovementDirection)
    case controlsOpened
    case reminderFired(ReminderKind)
    case dismissedReminder
    case automaticAction(AutomaticPetAction)
    case animationCompleted
}

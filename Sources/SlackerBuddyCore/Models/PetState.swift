import Foundation

public enum PetState: Equatable, Sendable {
    case idle
    case blink
    case sleeping
    case waking
    case petting
    case reminding
    case waving
    case reviewing
    case jumping
    case failed
    case waiting
    case running
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

public enum ExpressivePetAction: CaseIterable, Equatable, Sendable {
    case review
    case jump
    case fail
    case wait
    case run
}

public enum AutomaticPetAction: Equatable, Sendable {
    case blink
    case running(PetMovementDirection)
    case expressive(ExpressivePetAction)
}

public enum AutomaticRunDirectionMode: String, CaseIterable, Equatable, Sendable {
    case left
    case right
    case random
}

public enum PetEvent: Equatable, Sendable {
    case clicked
    case dragged(PetMovementDirection)
    case expressiveAction(ExpressivePetAction)
    case controlsOpened
    case reminderFired(ReminderKind)
    case dismissedReminder
    case automaticAction(AutomaticPetAction)
    case animationCompleted
}

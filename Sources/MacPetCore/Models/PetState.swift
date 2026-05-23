import Foundation

public enum PetState: Equatable, Sendable {
    case idle
    case blink
    case sleeping
    case waking
    case petting
    case reminding
}

public enum PetEvent: Equatable, Sendable {
    case clicked
    case dragged
    case controlsOpened
    case reminderFired
    case dismissedReminder
    case animationCompleted
}

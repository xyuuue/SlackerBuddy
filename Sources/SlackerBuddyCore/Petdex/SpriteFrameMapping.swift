import Foundation

public enum SpriteFrameMapping {
    public static func row(for state: PetState) -> Int {
        switch state {
        case .idle, .blink, .automaticBlink:
            return 0
        case .sleeping:
            return 8
        case .petting:
            return 3
        case .waking, .jumping:
            return 4
        case .failed:
            return 5
        case .reminding, .waving, .waiting:
            return 6
        case .running:
            return 7
        case .reviewing:
            return 8
        case .dragRunningRight, .automaticRunningRight:
            return 1
        case .dragRunningLeft, .automaticRunningLeft:
            return 2
        }
    }

    public static func row(forFrameName frameName: String, fallbackState state: PetState) -> Int {
        if frameName.hasPrefix("idle-") {
            return 0
        }
        if frameName.hasPrefix("run-right-") {
            return 1
        }
        if frameName.hasPrefix("run-left-") {
            return 2
        }
        if frameName.hasPrefix("petting-") {
            return 3
        }
        if frameName.hasPrefix("wake-") || frameName.hasPrefix("jump-") {
            return 4
        }
        if frameName.hasPrefix("failed-") {
            return 5
        }
        if frameName.hasPrefix("reminder-") || frameName.hasPrefix("wave-") || frameName.hasPrefix("waiting-") {
            return 6
        }
        if frameName.hasPrefix("running-") {
            return 7
        }
        if frameName.hasPrefix("sleep-") || frameName.hasPrefix("review-") {
            return 8
        }

        return row(for: state)
    }
}

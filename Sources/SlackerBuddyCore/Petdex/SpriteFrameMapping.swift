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
        case .waking:
            return 4
        case .reminding, .waving:
            return 6
        case .dragRunningRight, .automaticRunningRight:
            return 1
        case .dragRunningLeft, .automaticRunningLeft:
            return 2
        }
    }
}

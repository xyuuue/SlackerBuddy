import Foundation

public enum SpriteFrameMapping {
    public static func row(for state: PetState) -> Int {
        switch state {
        case .idle, .blink:
            return 0
        case .sleeping:
            return 8
        case .petting:
            return 3
        case .waking:
            return 4
        case .reminding:
            return 6
        }
    }
}

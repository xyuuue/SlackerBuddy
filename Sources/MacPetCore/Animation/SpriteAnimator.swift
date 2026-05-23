import Foundation

public struct SpriteAnimator: Sendable {
    public init() {}

    public func frame(for state: PetState, elapsed: TimeInterval, lowerDistractionMode: Bool) -> String {
        let frames = frames(for: state)
        let duration = duration(for: state, lowerDistractionMode: lowerDistractionMode)
        let elapsed = max(0, elapsed)
        let index = Int(elapsed / duration) % frames.count

        return frames[index]
    }

    private func frames(for state: PetState) -> [String] {
        switch state {
        case .idle:
            return ["idle-0", "idle-1", "tail-sway-0", "tail-sway-1"]
        case .blink:
            return ["blink-0", "blink-1"]
        case .sleeping:
            return ["sleep-0", "sleep-1"]
        case .waking:
            return ["wake-0", "wake-1"]
        case .petting:
            return ["petting-0", "petting-1"]
        case .reminding:
            return ["reminder-0", "reminder-1"]
        }
    }

    private func duration(for state: PetState, lowerDistractionMode: Bool) -> TimeInterval {
        switch state {
        case .idle where lowerDistractionMode:
            return 2.0
        case .idle:
            return 0.5
        case .blink, .waking, .petting, .reminding:
            return 0.25
        case .sleeping:
            return 1.0
        }
    }
}

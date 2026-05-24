import Foundation

public struct SpriteAnimator: Sendable {
    public init() {}

    public func frame(for state: PetState, elapsed: TimeInterval, lowerDistractionMode: Bool) -> String {
        let frames = frames(for: state, lowerDistractionMode: lowerDistractionMode)
        let duration = duration(for: state, lowerDistractionMode: lowerDistractionMode)
        let elapsed = max(0, elapsed)
        let index = Int(elapsed / duration) % frames.count

        return frames[index]
    }

    private func frames(for state: PetState, lowerDistractionMode: Bool) -> [String] {
        switch state {
        case .idle:
            return ["idle-0", "idle-1", "idle-2", "idle-3", "idle-4", "idle-5"]
        case .blink, .automaticBlink:
            return ["idle-4", "idle-5"]
        case .sleeping:
            return ["sleep-0", "sleep-1"]
        case .waking:
            return ["wake-0", "wake-1"]
        case .petting:
            return ["petting-0", "petting-1"]
        case .reminding, .waving:
            return state == .waving ? ["wave-0", "wave-1"] : ["reminder-0", "reminder-1"]
        case .dragRunningLeft where lowerDistractionMode,
            .automaticRunningLeft where lowerDistractionMode:
            return ["idle-0", "idle-1"]
        case .dragRunningLeft, .automaticRunningLeft:
            return ["run-left-0", "run-left-1", "run-left-2", "run-left-3", "run-left-4", "run-left-5", "run-left-6", "run-left-7"]
        case .dragRunningRight where lowerDistractionMode,
            .automaticRunningRight where lowerDistractionMode:
            return ["idle-0", "idle-1"]
        case .dragRunningRight, .automaticRunningRight:
            return ["run-right-0", "run-right-1", "run-right-2", "run-right-3", "run-right-4", "run-right-5", "run-right-6", "run-right-7"]
        }
    }

    private func duration(for state: PetState, lowerDistractionMode: Bool) -> TimeInterval {
        switch state {
        case .idle where lowerDistractionMode:
            return 2.0
        case .idle:
            return 0.5
        case .blink,
            .waking,
            .petting,
            .reminding,
            .waving,
            .dragRunningLeft,
            .dragRunningRight,
            .automaticBlink,
            .automaticRunningLeft,
            .automaticRunningRight:
            return 0.25
        case .sleeping:
            return 1.0
        }
    }
}

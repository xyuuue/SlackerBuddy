import Foundation

public struct SpriteAnimator: Sendable {
    private static let lowerDistractionBlinkLoop = ["idle-0", "idle-0", "idle-0", "idle-0", "idle-4", "idle-5"]

    public init() {}

    public func frame(for state: PetState, elapsed: TimeInterval, lowerDistractionMode: Bool) -> String {
        let frames = frames(for: state, lowerDistractionMode: lowerDistractionMode)
        let duration = duration(for: state, lowerDistractionMode: lowerDistractionMode)
        let elapsed = max(0, elapsed)
        let index = Int(elapsed / duration) % frames.count

        return frames[index]
    }

    private func frames(for state: PetState, lowerDistractionMode: Bool) -> [String] {
        if lowerDistractionMode {
            switch state {
            case .blink, .automaticBlink:
                return ["idle-4", "idle-5"]
            default:
                return Self.lowerDistractionBlinkLoop
            }
        }

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
        case .reviewing:
            return ["review-0", "review-1", "review-2", "review-3", "review-4", "review-5"]
        case .jumping:
            return ["jump-0", "jump-1", "jump-2", "jump-3", "jump-4"]
        case .failed:
            return ["failed-0", "failed-1", "failed-2", "failed-3", "failed-4", "failed-5", "failed-6", "failed-7"]
        case .waiting:
            return ["waiting-0", "waiting-1", "waiting-2", "waiting-3", "waiting-4", "waiting-5"]
        case .running:
            return ["running-0", "running-1", "running-2", "running-3", "running-4", "running-5"]
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
        if lowerDistractionMode {
            switch state {
            case .blink, .automaticBlink:
                return 0.25
            default:
                return 1.5
            }
        }

        switch state {
        case .idle:
            return 0.5
        case .blink,
            .waking,
            .petting,
            .reminding,
            .waving,
            .reviewing,
            .jumping,
            .failed,
            .waiting,
            .running,
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

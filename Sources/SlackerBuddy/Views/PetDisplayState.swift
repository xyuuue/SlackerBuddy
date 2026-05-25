import Observation

@MainActor
@Observable
public final class PetDisplayState {
    public var petScaleOverride: Double?

    public init() {}

    public func effectivePetScale(defaultScale: Double) -> Double {
        petScaleOverride ?? defaultScale
    }
}

import Foundation

public struct PetPreferences: Equatable, Sendable {
    public var reminderIntervalMinutes: Int
    public var sleepDelayMinutes: Int
    public var petScale: Double
    public var showPetOnLaunch: Bool
    public var systemNotificationsEnabled: Bool
    public var lowerDistractionMode: Bool

    public init(
        reminderIntervalMinutes: Int = 25,
        sleepDelayMinutes: Int = 30,
        petScale: Double = 1.0,
        showPetOnLaunch: Bool = true,
        systemNotificationsEnabled: Bool = false,
        lowerDistractionMode: Bool = false
    ) {
        self.reminderIntervalMinutes = max(1, reminderIntervalMinutes)
        self.sleepDelayMinutes = max(1, sleepDelayMinutes)
        self.petScale = min(max(petScale, 0.5), 3.0)
        self.showPetOnLaunch = showPetOnLaunch
        self.systemNotificationsEnabled = systemNotificationsEnabled
        self.lowerDistractionMode = lowerDistractionMode
    }
}

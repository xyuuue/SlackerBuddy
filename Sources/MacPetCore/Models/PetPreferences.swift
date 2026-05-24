import Foundation

public struct PetPreferences: Equatable, Sendable {
    public static let defaultSelectedPetID = "builtin.siamese-placeholder"

    public var reminderIntervalMinutes: Int
    public var sleepDelayMinutes: Int
    public var petScale: Double
    public var showPetOnLaunch: Bool
    public var systemNotificationsEnabled: Bool
    public var lowerDistractionMode: Bool
    public var language: AppLanguage
    public var selectedPetID: String

    public init(
        reminderIntervalMinutes: Int = 25,
        sleepDelayMinutes: Int = 30,
        petScale: Double = 1.0,
        showPetOnLaunch: Bool = true,
        systemNotificationsEnabled: Bool = false,
        lowerDistractionMode: Bool = false,
        language: AppLanguage = .system,
        selectedPetID: String = Self.defaultSelectedPetID
    ) {
        self.reminderIntervalMinutes = max(1, reminderIntervalMinutes)
        self.sleepDelayMinutes = max(1, sleepDelayMinutes)
        self.petScale = min(max(petScale, 0.5), 3.0)
        self.showPetOnLaunch = showPetOnLaunch
        self.systemNotificationsEnabled = systemNotificationsEnabled
        self.lowerDistractionMode = lowerDistractionMode
        self.language = language
        self.selectedPetID = selectedPetID
    }
}

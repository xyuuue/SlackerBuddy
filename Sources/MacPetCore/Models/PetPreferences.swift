import Foundation

public struct PetPreferences: Equatable, Sendable {
    public static let defaultSelectedPetID = "builtin.siamese-placeholder"

    public var reminderIntervalMinutes: Int
    public var restRemindersEnabled: Bool
    public var restBlockingEnabled: Bool
    public var restBlockingDurationSeconds: Int
    public var restBlockingScalePercent: Int
    public var waterRemindersEnabled: Bool
    public var waterIntervalMinutes: Int
    public var bubbleDurationSeconds: Int
    public var automaticActionsEnabled: Bool
    public var automaticActionIntervalMinutes: Int
    public var automaticRunningEnabled: Bool
    public var sleepDelayMinutes: Int
    public var petScale: Double
    public var showPetOnLaunch: Bool
    public var systemNotificationsEnabled: Bool
    public var lowerDistractionMode: Bool
    public var language: AppLanguage
    public var selectedPetID: String

    public init(
        reminderIntervalMinutes: Int = 45,
        sleepDelayMinutes: Int = 30,
        petScale: Double = 1.0,
        restRemindersEnabled: Bool = true,
        restBlockingEnabled: Bool = true,
        restBlockingDurationSeconds: Int = 15,
        restBlockingScalePercent: Int = 40,
        waterRemindersEnabled: Bool = true,
        waterIntervalMinutes: Int = 90,
        bubbleDurationSeconds: Int = 6,
        automaticActionsEnabled: Bool = true,
        automaticActionIntervalMinutes: Int = 8,
        automaticRunningEnabled: Bool = false,
        showPetOnLaunch: Bool = true,
        systemNotificationsEnabled: Bool = false,
        lowerDistractionMode: Bool = false,
        language: AppLanguage = .system,
        selectedPetID: String = Self.defaultSelectedPetID
    ) {
        self.reminderIntervalMinutes = max(1, reminderIntervalMinutes)
        self.restRemindersEnabled = restRemindersEnabled
        self.restBlockingEnabled = restBlockingEnabled
        self.restBlockingDurationSeconds = min(max(restBlockingDurationSeconds, 1), 300)
        self.restBlockingScalePercent = min(max(restBlockingScalePercent, 10), 90)
        self.waterRemindersEnabled = waterRemindersEnabled
        self.waterIntervalMinutes = min(max(waterIntervalMinutes, 1), 480)
        self.bubbleDurationSeconds = min(max(bubbleDurationSeconds, 1), 60)
        self.automaticActionsEnabled = automaticActionsEnabled
        self.automaticActionIntervalMinutes = min(max(automaticActionIntervalMinutes, 1), 120)
        self.automaticRunningEnabled = automaticRunningEnabled
        self.sleepDelayMinutes = max(1, sleepDelayMinutes)
        self.petScale = min(max(petScale, 0.5), 3.0)
        self.showPetOnLaunch = showPetOnLaunch
        self.systemNotificationsEnabled = systemNotificationsEnabled
        self.lowerDistractionMode = lowerDistractionMode
        self.language = language
        self.selectedPetID = selectedPetID
    }

    func replacing(
        reminderIntervalMinutes: Int? = nil,
        restRemindersEnabled: Bool? = nil,
        restBlockingEnabled: Bool? = nil,
        restBlockingDurationSeconds: Int? = nil,
        restBlockingScalePercent: Int? = nil,
        waterRemindersEnabled: Bool? = nil,
        waterIntervalMinutes: Int? = nil,
        bubbleDurationSeconds: Int? = nil,
        automaticActionsEnabled: Bool? = nil,
        automaticActionIntervalMinutes: Int? = nil,
        automaticRunningEnabled: Bool? = nil,
        sleepDelayMinutes: Int? = nil,
        petScale: Double? = nil,
        showPetOnLaunch: Bool? = nil,
        systemNotificationsEnabled: Bool? = nil,
        lowerDistractionMode: Bool? = nil,
        language: AppLanguage? = nil,
        selectedPetID: String? = nil
    ) -> PetPreferences {
        PetPreferences(
            reminderIntervalMinutes: reminderIntervalMinutes ?? self.reminderIntervalMinutes,
            sleepDelayMinutes: sleepDelayMinutes ?? self.sleepDelayMinutes,
            petScale: petScale ?? self.petScale,
            restRemindersEnabled: restRemindersEnabled ?? self.restRemindersEnabled,
            restBlockingEnabled: restBlockingEnabled ?? self.restBlockingEnabled,
            restBlockingDurationSeconds: restBlockingDurationSeconds ?? self.restBlockingDurationSeconds,
            restBlockingScalePercent: restBlockingScalePercent ?? self.restBlockingScalePercent,
            waterRemindersEnabled: waterRemindersEnabled ?? self.waterRemindersEnabled,
            waterIntervalMinutes: waterIntervalMinutes ?? self.waterIntervalMinutes,
            bubbleDurationSeconds: bubbleDurationSeconds ?? self.bubbleDurationSeconds,
            automaticActionsEnabled: automaticActionsEnabled ?? self.automaticActionsEnabled,
            automaticActionIntervalMinutes: automaticActionIntervalMinutes ?? self.automaticActionIntervalMinutes,
            automaticRunningEnabled: automaticRunningEnabled ?? self.automaticRunningEnabled,
            showPetOnLaunch: showPetOnLaunch ?? self.showPetOnLaunch,
            systemNotificationsEnabled: systemNotificationsEnabled ?? self.systemNotificationsEnabled,
            lowerDistractionMode: lowerDistractionMode ?? self.lowerDistractionMode,
            language: language ?? self.language,
            selectedPetID: selectedPetID ?? self.selectedPetID
        )
    }
}

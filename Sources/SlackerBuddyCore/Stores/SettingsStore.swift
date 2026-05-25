import Foundation
import Observation

@MainActor @Observable public final class SettingsStore {
    public private(set) var preferences: PetPreferences

    @ObservationIgnored
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.preferences = PetPreferences(
            reminderIntervalMinutes: defaults.integer(forKey: Keys.reminderIntervalMinutes, defaultValue: 45),
            petScale: defaults.double(forKey: Keys.petScale, defaultValue: 1.0),
            restRemindersEnabled: defaults.bool(forKey: Keys.restRemindersEnabled, defaultValue: true),
            restBlockingEnabled: defaults.bool(forKey: Keys.restBlockingEnabled, defaultValue: true),
            restBlockingDurationSeconds: defaults.integer(forKey: Keys.restBlockingDurationSeconds, defaultValue: 15),
            restBlockingScalePercent: defaults.integer(forKey: Keys.restBlockingScalePercent, defaultValue: 40),
            waterRemindersEnabled: defaults.bool(forKey: Keys.waterRemindersEnabled, defaultValue: true),
            waterIntervalMinutes: defaults.integer(forKey: Keys.waterIntervalMinutes, defaultValue: 90),
            bubbleDurationSeconds: defaults.integer(forKey: Keys.bubbleDurationSeconds, defaultValue: 6),
            automaticActionsEnabled: defaults.bool(forKey: Keys.automaticActionsEnabled, defaultValue: true),
            automaticActionIntervalMinutes: defaults.integer(forKey: Keys.automaticActionIntervalMinutes, defaultValue: 8),
            automaticRunningEnabled: defaults.bool(forKey: Keys.automaticRunningEnabled, defaultValue: false),
            automaticRunDirectionMode: defaults.automaticRunDirectionMode(forKey: Keys.automaticRunDirectionMode),
            showPetOnLaunch: defaults.bool(forKey: Keys.showPetOnLaunch, defaultValue: true),
            systemNotificationsEnabled: defaults.bool(forKey: Keys.systemNotificationsEnabled, defaultValue: false),
            lowerDistractionMode: defaults.bool(forKey: Keys.lowerDistractionMode, defaultValue: false),
            language: defaults.appLanguage(forKey: Keys.language),
            selectedPetID: defaults.string(forKey: Keys.selectedPetID) ?? PetPreferences.defaultSelectedPetID
        )
    }

    public func updateReminderInterval(minutes: Int) {
        preferences = preferences.replacing(reminderIntervalMinutes: minutes)
        persist()
    }

    public func updateRestRemindersEnabled(_ isEnabled: Bool) {
        preferences = preferences.replacing(restRemindersEnabled: isEnabled)
        persist()
    }

    public func updateRestBlockingEnabled(_ isEnabled: Bool) {
        preferences = preferences.replacing(restBlockingEnabled: isEnabled)
        persist()
    }

    public func updateRestBlockingDuration(seconds: Int) {
        preferences = preferences.replacing(restBlockingDurationSeconds: seconds)
        persist()
    }

    public func updateRestBlockingScale(percent: Int) {
        preferences = preferences.replacing(restBlockingScalePercent: percent)
        persist()
    }

    public func updateWaterRemindersEnabled(_ isEnabled: Bool) {
        preferences = preferences.replacing(waterRemindersEnabled: isEnabled)
        persist()
    }

    public func updateWaterInterval(minutes: Int) {
        preferences = preferences.replacing(waterIntervalMinutes: minutes)
        persist()
    }

    public func updateBubbleDuration(seconds: Int) {
        preferences = preferences.replacing(bubbleDurationSeconds: seconds)
        persist()
    }

    public func updateAutomaticActionsEnabled(_ isEnabled: Bool) {
        preferences = preferences.replacing(automaticActionsEnabled: isEnabled)
        persist()
    }

    public func updateAutomaticActionInterval(minutes: Int) {
        preferences = preferences.replacing(automaticActionIntervalMinutes: minutes)
        persist()
    }

    public func updateAutomaticRunningEnabled(_ isEnabled: Bool) {
        preferences = preferences.replacing(automaticRunningEnabled: isEnabled)
        persist()
    }

    public func updateAutomaticRunDirectionMode(_ mode: AutomaticRunDirectionMode) {
        preferences = preferences.replacing(automaticRunDirectionMode: mode)
        persist()
    }

    public func updatePetScale(_ scale: Double) {
        preferences = preferences.replacing(petScale: scale)
        persist()
    }

    public func updateShowPetOnLaunch(_ isEnabled: Bool) {
        preferences.showPetOnLaunch = isEnabled
        persist()
    }

    public func updateSystemNotificationsEnabled(_ isEnabled: Bool) {
        preferences.systemNotificationsEnabled = isEnabled
        persist()
    }

    public func updateLowerDistractionMode(_ isEnabled: Bool) {
        preferences.lowerDistractionMode = isEnabled
        persist()
    }

    public func updateLanguage(_ language: AppLanguage) {
        preferences.language = language
        persist()
    }

    public func updateSelectedPetID(_ petID: String) {
        preferences.selectedPetID = petID
        persist()
    }

    private func persist() {
        defaults.set(preferences.reminderIntervalMinutes, forKey: Keys.reminderIntervalMinutes)
        defaults.set(preferences.restRemindersEnabled, forKey: Keys.restRemindersEnabled)
        defaults.set(preferences.restBlockingEnabled, forKey: Keys.restBlockingEnabled)
        defaults.set(preferences.restBlockingDurationSeconds, forKey: Keys.restBlockingDurationSeconds)
        defaults.set(preferences.restBlockingScalePercent, forKey: Keys.restBlockingScalePercent)
        defaults.set(preferences.waterRemindersEnabled, forKey: Keys.waterRemindersEnabled)
        defaults.set(preferences.waterIntervalMinutes, forKey: Keys.waterIntervalMinutes)
        defaults.set(preferences.bubbleDurationSeconds, forKey: Keys.bubbleDurationSeconds)
        defaults.set(preferences.automaticActionsEnabled, forKey: Keys.automaticActionsEnabled)
        defaults.set(preferences.automaticActionIntervalMinutes, forKey: Keys.automaticActionIntervalMinutes)
        defaults.set(preferences.automaticRunningEnabled, forKey: Keys.automaticRunningEnabled)
        defaults.set(preferences.automaticRunDirectionMode.rawValue, forKey: Keys.automaticRunDirectionMode)
        defaults.set(preferences.petScale, forKey: Keys.petScale)
        defaults.set(preferences.showPetOnLaunch, forKey: Keys.showPetOnLaunch)
        defaults.set(preferences.systemNotificationsEnabled, forKey: Keys.systemNotificationsEnabled)
        defaults.set(preferences.lowerDistractionMode, forKey: Keys.lowerDistractionMode)
        defaults.set(preferences.language.rawValue, forKey: Keys.language)
        defaults.set(preferences.selectedPetID, forKey: Keys.selectedPetID)
    }

    private enum Keys {
        static let reminderIntervalMinutes = "settings.reminderIntervalMinutes"
        static let restRemindersEnabled = "settings.restRemindersEnabled"
        static let restBlockingEnabled = "settings.restBlockingEnabled"
        static let restBlockingDurationSeconds = "settings.restBlockingDurationSeconds"
        static let restBlockingScalePercent = "settings.restBlockingScalePercent"
        static let waterRemindersEnabled = "settings.waterRemindersEnabled"
        static let waterIntervalMinutes = "settings.waterIntervalMinutes"
        static let bubbleDurationSeconds = "settings.bubbleDurationSeconds"
        static let automaticActionsEnabled = "settings.automaticActionsEnabled"
        static let automaticActionIntervalMinutes = "settings.automaticActionIntervalMinutes"
        static let automaticRunningEnabled = "settings.automaticRunningEnabled"
        static let automaticRunDirectionMode = "settings.automaticRunDirectionMode"
        static let petScale = "settings.petScale"
        static let showPetOnLaunch = "settings.showPetOnLaunch"
        static let systemNotificationsEnabled = "settings.systemNotificationsEnabled"
        static let lowerDistractionMode = "settings.lowerDistractionMode"
        static let language = "settings.language"
        static let selectedPetID = "settings.selectedPetID"
    }
}

private extension UserDefaults {
    func integer(forKey key: String, defaultValue: Int) -> Int {
        object(forKey: key) == nil ? defaultValue : integer(forKey: key)
    }

    func double(forKey key: String, defaultValue: Double) -> Double {
        object(forKey: key) == nil ? defaultValue : double(forKey: key)
    }

    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        object(forKey: key) == nil ? defaultValue : bool(forKey: key)
    }

    func appLanguage(forKey key: String) -> AppLanguage {
        guard let rawValue = string(forKey: key) else {
            return .system
        }
        return AppLanguage(rawValue: rawValue) ?? .system
    }

    func automaticRunDirectionMode(forKey key: String) -> AutomaticRunDirectionMode {
        guard let rawValue = string(forKey: key) else {
            return .random
        }
        return AutomaticRunDirectionMode(rawValue: rawValue) ?? .random
    }
}

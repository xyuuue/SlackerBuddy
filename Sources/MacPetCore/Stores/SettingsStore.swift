import Foundation
import Observation

@MainActor @Observable public final class SettingsStore {
    public private(set) var preferences: PetPreferences

    @ObservationIgnored
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.preferences = PetPreferences(
            reminderIntervalMinutes: defaults.integer(forKey: Keys.reminderIntervalMinutes, defaultValue: 25),
            sleepDelayMinutes: defaults.integer(forKey: Keys.sleepDelayMinutes, defaultValue: 30),
            petScale: defaults.double(forKey: Keys.petScale, defaultValue: 1.0),
            showPetOnLaunch: defaults.bool(forKey: Keys.showPetOnLaunch, defaultValue: true),
            systemNotificationsEnabled: defaults.bool(forKey: Keys.systemNotificationsEnabled, defaultValue: false),
            lowerDistractionMode: defaults.bool(forKey: Keys.lowerDistractionMode, defaultValue: false),
            language: defaults.appLanguage(forKey: Keys.language),
            selectedPetID: defaults.string(forKey: Keys.selectedPetID) ?? PetPreferences.defaultSelectedPetID
        )
    }

    public func updateReminderInterval(minutes: Int) {
        preferences = PetPreferences(
            reminderIntervalMinutes: minutes,
            sleepDelayMinutes: preferences.sleepDelayMinutes,
            petScale: preferences.petScale,
            showPetOnLaunch: preferences.showPetOnLaunch,
            systemNotificationsEnabled: preferences.systemNotificationsEnabled,
            lowerDistractionMode: preferences.lowerDistractionMode,
            language: preferences.language,
            selectedPetID: preferences.selectedPetID
        )
        persist()
    }

    public func updateSleepDelay(minutes: Int) {
        preferences = PetPreferences(
            reminderIntervalMinutes: preferences.reminderIntervalMinutes,
            sleepDelayMinutes: minutes,
            petScale: preferences.petScale,
            showPetOnLaunch: preferences.showPetOnLaunch,
            systemNotificationsEnabled: preferences.systemNotificationsEnabled,
            lowerDistractionMode: preferences.lowerDistractionMode,
            language: preferences.language,
            selectedPetID: preferences.selectedPetID
        )
        persist()
    }

    public func updatePetScale(_ scale: Double) {
        preferences = PetPreferences(
            reminderIntervalMinutes: preferences.reminderIntervalMinutes,
            sleepDelayMinutes: preferences.sleepDelayMinutes,
            petScale: scale,
            showPetOnLaunch: preferences.showPetOnLaunch,
            systemNotificationsEnabled: preferences.systemNotificationsEnabled,
            lowerDistractionMode: preferences.lowerDistractionMode,
            language: preferences.language,
            selectedPetID: preferences.selectedPetID
        )
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
        defaults.set(preferences.sleepDelayMinutes, forKey: Keys.sleepDelayMinutes)
        defaults.set(preferences.petScale, forKey: Keys.petScale)
        defaults.set(preferences.showPetOnLaunch, forKey: Keys.showPetOnLaunch)
        defaults.set(preferences.systemNotificationsEnabled, forKey: Keys.systemNotificationsEnabled)
        defaults.set(preferences.lowerDistractionMode, forKey: Keys.lowerDistractionMode)
        defaults.set(preferences.language.rawValue, forKey: Keys.language)
        defaults.set(preferences.selectedPetID, forKey: Keys.selectedPetID)
    }

    private enum Keys {
        static let reminderIntervalMinutes = "settings.reminderIntervalMinutes"
        static let sleepDelayMinutes = "settings.sleepDelayMinutes"
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
}

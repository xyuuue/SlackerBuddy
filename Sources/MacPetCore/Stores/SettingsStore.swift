import Foundation

public final class SettingsStore {
    public private(set) var preferences: PetPreferences

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.preferences = PetPreferences(
            reminderIntervalMinutes: defaults.integer(forKey: Keys.reminderIntervalMinutes, defaultValue: 25),
            sleepDelayMinutes: defaults.integer(forKey: Keys.sleepDelayMinutes, defaultValue: 30),
            petScale: defaults.double(forKey: Keys.petScale, defaultValue: 1.0),
            showPetOnLaunch: defaults.bool(forKey: Keys.showPetOnLaunch, defaultValue: true),
            systemNotificationsEnabled: defaults.bool(forKey: Keys.systemNotificationsEnabled, defaultValue: false),
            lowerDistractionMode: defaults.bool(forKey: Keys.lowerDistractionMode, defaultValue: false)
        )
    }

    public func updateReminderInterval(minutes: Int) {
        preferences = PetPreferences(
            reminderIntervalMinutes: minutes,
            sleepDelayMinutes: preferences.sleepDelayMinutes,
            petScale: preferences.petScale,
            showPetOnLaunch: preferences.showPetOnLaunch,
            systemNotificationsEnabled: preferences.systemNotificationsEnabled,
            lowerDistractionMode: preferences.lowerDistractionMode
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
            lowerDistractionMode: preferences.lowerDistractionMode
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
            lowerDistractionMode: preferences.lowerDistractionMode
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

    private func persist() {
        defaults.set(preferences.reminderIntervalMinutes, forKey: Keys.reminderIntervalMinutes)
        defaults.set(preferences.sleepDelayMinutes, forKey: Keys.sleepDelayMinutes)
        defaults.set(preferences.petScale, forKey: Keys.petScale)
        defaults.set(preferences.showPetOnLaunch, forKey: Keys.showPetOnLaunch)
        defaults.set(preferences.systemNotificationsEnabled, forKey: Keys.systemNotificationsEnabled)
        defaults.set(preferences.lowerDistractionMode, forKey: Keys.lowerDistractionMode)
    }

    private enum Keys {
        static let reminderIntervalMinutes = "settings.reminderIntervalMinutes"
        static let sleepDelayMinutes = "settings.sleepDelayMinutes"
        static let petScale = "settings.petScale"
        static let showPetOnLaunch = "settings.showPetOnLaunch"
        static let systemNotificationsEnabled = "settings.systemNotificationsEnabled"
        static let lowerDistractionMode = "settings.lowerDistractionMode"
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
}

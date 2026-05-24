import Foundation
import MacPetCore

let settingsStoreTests: [TestCase] = [
    TestCase(name: "defaults match product decisions") {
        let suiteName = "MacPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        try expect(store.preferences.restRemindersEnabled == true, "Expected rest reminders enabled by default")
        try expect(store.preferences.reminderIntervalMinutes == 45, "Expected rest interval to default to 45")
        try expect(store.preferences.restBlockingEnabled == true, "Expected rest blocking enabled by default")
        try expect(store.preferences.restBlockingDurationSeconds == 15, "Expected blocking duration to default to 15 seconds")
        try expect(store.preferences.restBlockingScalePercent == 40, "Expected blocking scale to default to 40 percent")
        try expect(store.preferences.waterRemindersEnabled == true, "Expected water reminders enabled by default")
        try expect(store.preferences.waterIntervalMinutes == 90, "Expected water interval to default to 90")
        try expect(store.preferences.bubbleDurationSeconds == 6, "Expected bubble duration to default to 6 seconds")
        try expect(store.preferences.automaticActionsEnabled == true, "Expected automatic actions enabled by default")
        try expect(store.preferences.automaticActionIntervalMinutes == 8, "Expected automatic action interval to default to 8")
        try expect(store.preferences.automaticRunningEnabled == false, "Expected automatic running off by default")
        try expect(store.preferences.sleepDelayMinutes == 30, "Expected sleep delay to default to 30")
        try expect(store.preferences.petScale == 1.0, "Expected pet scale to default to 1.0")
        try expect(store.preferences.showPetOnLaunch == true, "Expected pet to show on launch by default")
        try expect(store.preferences.systemNotificationsEnabled == false, "Expected system notifications to default off")
        try expect(store.preferences.lowerDistractionMode == false, "Expected lower distraction mode to default off")
    },
    TestCase(name: "saves language and selected pet id after reload from same suite") {
        let suiteName = "MacPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.updateLanguage(.chinese)
        store.updateSelectedPetID("siamese-cat")

        let reloadedStore = SettingsStore(defaults: defaults)

        try expect(reloadedStore.preferences.language == .chinese, "Expected language to persist")
        try expect(reloadedStore.preferences.selectedPetID == "siamese-cat", "Expected selected pet id to persist")
    },
    TestCase(name: "saves custom reminder interval and scale after reload from same suite") {
        let suiteName = "MacPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.updateReminderInterval(minutes: 45)
        store.updatePetScale(1.75)

        let reloadedStore = SettingsStore(defaults: defaults)

        try expect(reloadedStore.preferences.reminderIntervalMinutes == 45, "Expected reminder interval to persist after reload")
        try expect(reloadedStore.preferences.petScale == 1.75, "Expected pet scale to persist after reload")
    },
    TestCase(name: "saves reminder and autonomy preferences after reload from same suite") {
        let suiteName = "MacPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)
        store.updateRestRemindersEnabled(false)
        store.updateRestBlockingEnabled(false)
        store.updateRestBlockingDuration(seconds: 30)
        store.updateRestBlockingScale(percent: 55)
        store.updateWaterRemindersEnabled(false)
        store.updateWaterInterval(minutes: 120)
        store.updateBubbleDuration(seconds: 9)
        store.updateAutomaticActionsEnabled(false)
        store.updateAutomaticActionInterval(minutes: 12)
        store.updateAutomaticRunningEnabled(true)

        let reloadedStore = SettingsStore(defaults: defaults)

        try expect(reloadedStore.preferences.restRemindersEnabled == false, "Expected rest reminder toggle to persist")
        try expect(reloadedStore.preferences.restBlockingEnabled == false, "Expected rest blocking toggle to persist")
        try expect(reloadedStore.preferences.restBlockingDurationSeconds == 30, "Expected blocking duration to persist")
        try expect(reloadedStore.preferences.restBlockingScalePercent == 55, "Expected blocking scale to persist")
        try expect(reloadedStore.preferences.waterRemindersEnabled == false, "Expected water reminder toggle to persist")
        try expect(reloadedStore.preferences.waterIntervalMinutes == 120, "Expected water interval to persist")
        try expect(reloadedStore.preferences.bubbleDurationSeconds == 9, "Expected bubble duration to persist")
        try expect(reloadedStore.preferences.automaticActionsEnabled == false, "Expected automatic action toggle to persist")
        try expect(reloadedStore.preferences.automaticActionIntervalMinutes == 12, "Expected automatic action interval to persist")
        try expect(reloadedStore.preferences.automaticRunningEnabled == true, "Expected automatic running toggle to persist")
    },
    TestCase(name: "clamps invalid values") {
        let lowPreferences = PetPreferences(
            reminderIntervalMinutes: 0,
            sleepDelayMinutes: -4,
            petScale: 0.1,
            restBlockingDurationSeconds: 0,
            restBlockingScalePercent: 5,
            waterIntervalMinutes: 0,
            bubbleDurationSeconds: 0,
            automaticActionIntervalMinutes: 0
        )
        let highPreferences = PetPreferences(petScale: 9.0)

        try expect(lowPreferences.reminderIntervalMinutes == 1, "Expected reminder interval 0 to clamp to 1")
        try expect(lowPreferences.sleepDelayMinutes == 1, "Expected sleep delay -4 to clamp to 1")
        try expect(lowPreferences.petScale == 0.5, "Expected pet scale 0.1 to clamp to 0.5")
        try expect(lowPreferences.restBlockingDurationSeconds == 1, "Expected blocking duration to clamp to 1")
        try expect(lowPreferences.restBlockingScalePercent == 10, "Expected blocking scale to clamp to 10")
        try expect(lowPreferences.waterIntervalMinutes == 1, "Expected water interval to clamp to 1")
        try expect(lowPreferences.bubbleDurationSeconds == 1, "Expected bubble duration to clamp to 1")
        try expect(lowPreferences.automaticActionIntervalMinutes == 1, "Expected automatic action interval to clamp to 1")
        try expect(highPreferences.petScale == 3.0, "Expected pet scale 9.0 to clamp to 3.0")
    }
]

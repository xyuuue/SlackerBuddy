import Foundation
import MacPetCore

let settingsStoreTests: [TestCase] = [
    TestCase(name: "defaults match product decisions") {
        let suiteName = "MacPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = SettingsStore(defaults: defaults)

        try expect(store.preferences.reminderIntervalMinutes == 25, "Expected reminder interval to default to 25")
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
    TestCase(name: "clamps invalid values") {
        let lowPreferences = PetPreferences(
            reminderIntervalMinutes: 0,
            sleepDelayMinutes: -4,
            petScale: 0.1
        )
        let highPreferences = PetPreferences(petScale: 9.0)

        try expect(lowPreferences.reminderIntervalMinutes == 1, "Expected reminder interval 0 to clamp to 1")
        try expect(lowPreferences.sleepDelayMinutes == 1, "Expected sleep delay -4 to clamp to 1")
        try expect(lowPreferences.petScale == 0.5, "Expected pet scale 0.1 to clamp to 0.5")
        try expect(highPreferences.petScale == 3.0, "Expected pet scale 9.0 to clamp to 3.0")
    }
]

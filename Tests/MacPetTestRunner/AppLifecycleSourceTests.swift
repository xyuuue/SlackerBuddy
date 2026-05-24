import Foundation

let appLifecycleSourceTests: [TestCase] = [
    TestCase(name: "pet view does not own reminder scheduler lifecycle") {
        let sourceURL = URL(fileURLWithPath: "Sources/MacPet/Views/PetView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        try expect(!source.contains("scheduler.start("), "PetView should not start the reminder scheduler")
        try expect(!source.contains("scheduler.tick("), "PetView should not tick the reminder scheduler")
        try expect(!source.contains("scheduler.updateInterval("), "PetView should not update scheduler intervals")
        try expect(!source.contains("scheduler.onReminder"), "PetView should not assign reminder callbacks")
    },
    TestCase(name: "window movement is reported as pet interaction") {
        let controllerSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )
        let runtimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(controllerSource.contains("public var onMoved: (() -> Void)?"), "PetWindowController should expose a movement callback")
        try expect(controllerSource.contains("self?.onMoved?()"), "PetWindowController should invoke movement callback after window moves")
        try expect(runtimeSource.contains("petWindowController.onMoved"), "AppRuntime should bind window movement to pet state")
        try expect(runtimeSource.contains("handlePetWindowMoved()"), "AppRuntime should route window movement through reminder-aware handler")
        try expect(runtimeSource.contains("scheduler.dismissActiveReminder()"), "Dragging during a reminder should restart the reminder scheduler")
        try expect(runtimeSource.contains("handle(.dismissedReminder)"), "Dragging during a reminder should dismiss reminder state")
        try expect(runtimeSource.contains("handle(.dragged)"), "Window movement should reset pet inactivity through dragged event outside reminders")
    },
    TestCase(name: "settings can reset pet position") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let runtimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(settingsSource.contains("Button(strings.text(.resetPetPosition))"), "Settings should expose reset pet position action")
        try expect(settingsSource.contains("onResetPetPosition?()"), "Settings reset action should call its runtime callback")
        try expect(runtimeSource.contains("func resetPetPosition()"), "AppRuntime should expose reset position action")
        try expect(runtimeSource.contains("petWindowController.resetPosition"), "AppRuntime should delegate reset position to window controller")
        try expect(windowSource.contains("func resetPosition"), "PetWindowController should support resetting persisted position")
        try expect(windowSource.contains("defaults.removeObject(forKey: frameDefaultsKey)"), "Reset should clear persisted pet frame")
    },
    TestCase(name: "runtime connects settings to localized Petdex pets") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/PetView.swift"),
            encoding: .utf8
        )
        let settingsViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/SettingsView.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("PetdexCatalog"), "Expected runtime to own PetdexCatalog")
        try expect(appRuntimeSource.contains("refreshPetCatalog"), "Expected runtime to refresh Petdex pets")
        try expect(appRuntimeSource.contains("selectedPetAsset"), "Expected runtime to resolve selected pet asset")
        try expect(petViewSource.contains("PetSpriteSheetView"), "Expected PetView to render Petdex sprites")
        try expect(settingsViewSource.contains("Picker(strings.text(.languageLabel)"), "Expected localized language picker")
        try expect(settingsViewSource.contains("Picker(strings.text(.petLabel)"), "Expected localized pet picker")
    },
    TestCase(name: "menu labels use localized runtime strings") {
        let macPetAppSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/MacPetApp.swift"),
            encoding: .utf8
        )

        try expect(!macPetAppSource.contains("Button(\"Show Pet\")"), "Show Pet menu label should not be hard-coded")
        try expect(!macPetAppSource.contains("Button(\"Hide Pet\")"), "Hide Pet menu label should not be hard-coded")
        try expect(!macPetAppSource.contains("Button(\"Quit\")"), "Quit menu label should not be hard-coded")
        try expect(macPetAppSource.contains("Button(runtime.localizedStrings.text(.showPetMenu))"), "Show Pet menu label should use localized strings")
        try expect(macPetAppSource.contains("Button(runtime.localizedStrings.text(.hidePetMenu))"), "Hide Pet menu label should use localized strings")
        try expect(macPetAppSource.contains("Button(runtime.localizedStrings.text(.quitMenu))"), "Quit menu label should use localized strings")
    },
    TestCase(name: "settings refreshes Petdex catalog when opened") {
        let macPetAppSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/MacPetApp.swift"),
            encoding: .utf8
        )

        try expect(macPetAppSource.contains("availablePets: runtime.availablePets"), "Settings picker should use runtime Petdex pets")
        try expect(macPetAppSource.contains(".onAppear"), "Settings should refresh when the settings scene appears")
        try expect(macPetAppSource.contains("runtime.refreshPetCatalog()"), "Settings should refresh Petdex catalog when opened")
    }
]

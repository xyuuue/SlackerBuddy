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

        try expect(controllerSource.contains("public var onMoved: ((PetMovementDirection) -> Void)?"), "PetWindowController should expose a directional movement callback")
        try expect(controllerSource.contains("movementDirection(from:"), "PetWindowController should infer movement direction")
        try expect(controllerSource.contains("onMoved?(direction)"), "PetWindowController should invoke movement callback with direction after window moves")
        try expect(runtimeSource.contains("petWindowController.onMoved"), "AppRuntime should bind window movement to pet state")
        try expect(runtimeSource.contains("handlePetWindowMoved(direction:"), "AppRuntime should route directional window movement through reminder-aware handler")
        try expect(runtimeSource.contains("scheduler.dismissActiveReminder()"), "Dragging during a reminder should restart the reminder scheduler")
        try expect(runtimeSource.contains("handle(.dismissedReminder)"), "Dragging during a reminder should dismiss reminder state")
        try expect(runtimeSource.contains("handle(.dragged("), "Window movement should reset pet inactivity through directional dragged event outside reminders")
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
    },
    TestCase(name: "runtime normalizes removed selected Petdex pet") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("settings.updateSelectedPetID(PetAsset.builtinID)"), "Refreshing Petdex should persist builtin selection when saved pet is gone")
    },
    TestCase(name: "runtime refreshes visible pet window after Petdex refresh changes selection") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("let previousSelectedPetID = selectedPetAsset.id"), "Runtime should capture selected pet before catalog refresh")
        try expect(appRuntimeSource.contains("if selectedPetAsset.id != previousSelectedPetID"), "Runtime should detect selected pet changes after catalog refresh")
        try expect(appRuntimeSource.contains("refreshPetWindowIfNeeded()"), "Runtime should refresh visible pet window after selected pet changes")
    },
    TestCase(name: "runtime does not reshow hidden pet during refresh") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("petWindowController.window?.isVisible == true"), "Runtime should refresh pet window only when the pet window is visible")
    },
    TestCase(name: "settings visible copy is fully localized") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let localizedStringsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPetCore/Localization/LocalizedStrings.swift"),
            encoding: .utf8
        )

        try expect(!settingsSource.contains(") min\""), "Settings duration labels should not hard-code English min suffix")
        try expect(!settingsSource.contains("return \"System\""), "System language label should be localized")
        try expect(localizedStringsSource.contains("case minuteSuffix"), "Localized strings should include minute suffix")
        try expect(localizedStringsSource.contains("case systemLanguageOption"), "Localized strings should include system language option")
    },
    TestCase(name: "settings exposes reminder and automatic action controls") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/SettingsView.swift"),
            encoding: .utf8
        )

        try expect(settingsSource.contains("Toggle(strings.text(.enableRestReminders)"), "Settings should expose rest reminder toggle")
        try expect(settingsSource.contains("Stepper(value: reminderIntervalMinutes"), "Settings should expose rest interval stepper")
        try expect(settingsSource.contains("Toggle(strings.text(.restBlockingEnabled)"), "Settings should expose blocking toggle")
        try expect(settingsSource.contains("Stepper(value: restBlockingDurationSeconds"), "Settings should expose blocking duration stepper")
        try expect(settingsSource.contains("Stepper(value: restBlockingScalePercent"), "Settings should expose blocking scale stepper")
        try expect(settingsSource.contains("Toggle(strings.text(.enableWaterReminders)"), "Settings should expose water toggle")
        try expect(settingsSource.contains("Stepper(value: waterIntervalMinutes"), "Settings should expose water interval stepper")
        try expect(settingsSource.contains("Stepper(value: bubbleDurationSeconds"), "Settings should expose bubble duration stepper")
        try expect(settingsSource.contains("Toggle(strings.text(.enableAutomaticActions)"), "Settings should expose automatic actions toggle")
        try expect(settingsSource.contains("Stepper(value: automaticActionIntervalMinutes"), "Settings should expose automatic frequency stepper")
        try expect(settingsSource.contains("Toggle(strings.text(.enableAutomaticRunning)"), "Settings should expose automatic running toggle")
    },
    TestCase(name: "settings shows system notification feedback") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let macPetAppSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/MacPetApp.swift"),
            encoding: .utf8
        )

        try expect(settingsSource.contains("notificationPermissionStatus"), "Settings should receive notification permission status")
        try expect(settingsSource.contains("notificationStatusText"), "Settings should render notification status feedback")
        try expect(appRuntimeSource.contains("notificationPermissionStatus"), "Runtime should track notification permission status")
        try expect(appRuntimeSource.contains("case false"), "Runtime should handle denied notification authorization")
        try expect(appRuntimeSource.contains("settings.updateSystemNotificationsEnabled(false)"), "Runtime should switch toggle off when authorization fails or is denied")
        try expect(macPetAppSource.contains("notificationPermissionStatus: runtime.notificationPermissionStatus"), "App should pass runtime notification status into settings")
    },
    TestCase(name: "Petdex sprite renderer caches atlas instead of decoding every frame") {
        let spriteViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Animation/PetSpriteSheetView.swift"),
            encoding: .utf8
        )

        try expect(spriteViewSource.contains("PetSpriteSheetFrameCache"), "Sprite renderer should use a frame cache")
        try expect(!spriteViewSource.contains("NSImage(contentsOf: spriteSheetURL)"), "Sprite renderer should not decode the atlas directly on each frame")
    },
    TestCase(name: "runtime centralizes rest and water reminder priority") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("handleDueReminders()"), "Runtime should centralize rest and water priority")
        try expect(appRuntimeSource.contains("restReminderScheduler.tick()"), "Runtime should tick rest scheduler")
        try expect(appRuntimeSource.contains("waterReminderScheduler.tick()"), "Runtime should tick water scheduler")
        try expect(appRuntimeSource.contains("if restReminderScheduler.isActive"), "Rest reminder should take priority")
    },
    TestCase(name: "runtime wires automatic scheduler and blocking overlay") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("restReminderScheduler"), "Runtime should own rest scheduler")
        try expect(appRuntimeSource.contains("waterReminderScheduler"), "Runtime should own water scheduler")
        try expect(appRuntimeSource.contains("automaticActionScheduler"), "Runtime should own automatic action scheduler")
        try expect(appRuntimeSource.contains("showRestBlockingOverlay"), "Runtime should show rest blocking overlay")
        try expect(appRuntimeSource.contains("hideRestBlockingOverlay"), "Runtime should hide rest blocking overlay")
        try expect(windowSource.contains("presentBlockingOverlay"), "Window controller should present blocking overlay")
        try expect(windowSource.contains("restoreFromBlockingOverlay"), "Window controller should restore after blocking overlay")
        try expect(!windowSource.contains("saveCurrentFrame()") || windowSource.contains("isBlockingOverlayActive"), "Blocking overlay should not persist as normal placement")
    },
    TestCase(name: "pet view delegates reminder dismissal to runtime") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/PetView.swift"),
            encoding: .utf8
        )

        try expect(petViewSource.contains("private let onDismissReminder: () -> Void"), "PetView should receive a runtime-owned reminder dismissal callback")
        try expect(petViewSource.contains("onDismissReminder()"), "PetView should invoke the runtime dismissal callback")
        try expect(!petViewSource.contains("scheduler.dismissActiveReminder()"), "PetView should not dismiss only the legacy rest scheduler")
        try expect(appRuntimeSource.contains("onDismissReminder: { [weak self] in"), "Runtime should pass a kind-aware dismissal callback into PetView")
        try expect(appRuntimeSource.contains("self?.dismissActiveReminder()"), "Runtime dismissal callback should route through active reminder kind handling")
    },
    TestCase(name: "blocking overlay frame changes do not report movement") {
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(windowSource.contains("isProgrammaticFrameChange"), "Window controller should track programmatic frame changes")
        try expect(windowSource.contains("performProgrammaticFrameChange"), "Blocking overlay should wrap programmatic frame changes")
        try expect(windowSource.contains("guard self?.isProgrammaticFrameChange == false else"), "Programmatic frame changes should suppress movement callbacks")
        try expect(!windowSource.contains("pendingProgrammaticMoveNotifications"), "Programmatic suppression should not leave stale pending movement notifications")
        try expect(!windowSource.contains("consumeProgrammaticMoveNotification()"), "Programmatic suppression should not consume the next real user move")
        try expect(!windowSource.contains("window.setFrame(frame, display: true, animate: true)"), "Blocking overlay frame changes should not animate through extra move notifications")

        guard let moveObserverStart = windowSource.range(of: "forName: NSWindow.didMoveNotification") else {
            throw TestFailure.failed("Expected window controller to observe move notifications")
        }
        guard let resizeObserverStart = windowSource.range(of: "forName: NSWindow.didResizeNotification") else {
            throw TestFailure.failed("Expected window controller to observe resize notifications")
        }

        let moveObserver = String(windowSource[moveObserverStart.lowerBound..<resizeObserverStart.lowerBound])
        guard let guardRange = moveObserver.range(of: "guard self?.isProgrammaticFrameChange == false else") else {
            throw TestFailure.failed("Expected move observer to suppress programmatic notifications")
        }
        guard let saveRange = moveObserver.range(of: "saveFrame()") else {
            throw TestFailure.failed("Expected move observer to save user-moved frames")
        }

        try expect(guardRange.lowerBound < saveRange.lowerBound, "Move observer should suppress programmatic notifications before saving frames")
    },
    TestCase(name: "runtime defers automatic actions while reminders or blocking overlay are active") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("shouldTickAutomaticActionScheduler"), "Runtime should centralize automatic action tick eligibility")
        try expect(appRuntimeSource.contains("stateMachine.state == .idle"), "Automatic scheduler should only tick while state is idle")
        try expect(appRuntimeSource.contains("stateMachine.activeReminderKind == nil"), "Automatic scheduler should not tick while a reminder is active")
        try expect(appRuntimeSource.contains("!isRestBlockingOverlayActive"), "Automatic scheduler should not tick while blocking overlay is active")
        try expect(!appRuntimeSource.contains("automaticActionScheduler.dismissActive()\n            return"), "Automatic scheduler should defer instead of consuming due work while non-idle")
    },
    TestCase(name: "runtime does not preempt active reminders with another reminder") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("guard stateMachine.activeReminderKind == nil else"), "Runtime should not tick reminder schedulers while another reminder is active")
        try expect(appRuntimeSource.contains("tickReminderSchedulers()"), "Runtime should separate reminder ticking from automatic action ticking")
        try expect(appRuntimeSource.contains("restReminderScheduler.stop()"), "Disabling rest reminders should stop the legacy rest scheduler")
    },
    TestCase(name: "runtime completes automatic action animations") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("stateMachine.state == .automaticBlink"), "Runtime should complete automatic blink animations")
        try expect(appRuntimeSource.contains("stateMachine.state == .automaticRunningLeft"), "Runtime should complete automatic left running animations")
        try expect(appRuntimeSource.contains("stateMachine.state == .automaticRunningRight"), "Runtime should complete automatic right running animations")
    },
    TestCase(name: "runtime gives immediate automatic action and running feedback") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("triggerAutomaticActionFeedback()"), "Runtime should trigger automatic feedback immediately when enabled")
        try expect(appRuntimeSource.contains("performAutomaticRun(direction:"), "Runtime should move the pet during automatic running")
        try expect(windowSource.contains("moveHorizontally(points:"), "Window controller should expose programmatic horizontal movement")
        try expect(windowSource.contains("performProgrammaticFrameChange"), "Automatic movement should be programmatic and not count as user drag")
    },
    TestCase(name: "pet view auto-hides reminder bubble without dismissing reminder") {
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/MacPet/Views/PetView.swift"),
            encoding: .utf8
        )

        try expect(petViewSource.contains("bubbleDurationSeconds"), "PetView should use configured bubble duration")
        try expect(petViewSource.contains("Task.sleep"), "PetView should auto-hide bubbles after a delay")
        try expect(petViewSource.contains("isBubbleVisible"), "PetView should hide bubble without dismissing reminder")
    }
]

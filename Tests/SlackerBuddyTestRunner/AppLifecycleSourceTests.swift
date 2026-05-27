import Foundation
import ImageIO

let appLifecycleSourceTests: [TestCase] = [
    TestCase(name: "pet view does not own reminder scheduler lifecycle") {
        let sourceURL = URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift")
        let source = try String(contentsOf: sourceURL, encoding: .utf8)

        try expect(!source.contains("scheduler.start("), "PetView should not start the reminder scheduler")
        try expect(!source.contains("scheduler.tick("), "PetView should not tick the reminder scheduler")
        try expect(!source.contains("scheduler.updateInterval("), "PetView should not update scheduler intervals")
        try expect(!source.contains("scheduler.onReminder"), "PetView should not assign reminder callbacks")
    },
    TestCase(name: "window movement is reported as pet interaction") {
        let controllerSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )
        let runtimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
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
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let runtimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
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
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )
        let settingsViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/SettingsView.swift"),
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
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/SlackerBuddyApp.swift"),
            encoding: .utf8
        )

        try expect(!macPetAppSource.contains("Button(\"Show Pet\")"), "Show Pet menu label should not be hard-coded")
        try expect(!macPetAppSource.contains("Button(\"Hide Pet\")"), "Hide Pet menu label should not be hard-coded")
        try expect(!macPetAppSource.contains("Button(\"Quit\")"), "Quit menu label should not be hard-coded")
        try expect(macPetAppSource.contains("Button(runtime.localizedStrings.text(.showPetMenu))"), "Show Pet menu label should use localized strings")
        try expect(macPetAppSource.contains("Button(runtime.localizedStrings.text(.hidePetMenu))"), "Hide Pet menu label should use localized strings")
        try expect(macPetAppSource.contains("Button(runtime.localizedStrings.text(.quitMenu))"), "Quit menu label should use localized strings")
    },
    TestCase(name: "app is branded as SlackerBuddy with custom paw icons") {
        let macPetAppSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/SlackerBuddyApp.swift"),
            encoding: .utf8
        )
        let notificationSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddyCore/Services/NotificationClient.swift"),
            encoding: .utf8
        )
        let buildScript = try String(
            contentsOf: URL(fileURLWithPath: "script/build_and_run.sh"),
            encoding: .utf8
        )

        try expect(macPetAppSource.contains("SlackerBuddy"), "Menu bar app label should use SlackerBuddy")
        try expect(macPetAppSource.contains("SlackerBuddyMenuBarIcon"), "Menu bar should attempt to load the custom paw toolbar icon")
        try expect(notificationSource.contains("SlackerBuddy"), "Notification title should use SlackerBuddy")
        try expect(buildScript.contains("APP_NAME=\"SlackerBuddy\""), "Packaged app should be named SlackerBuddy")
        try expect(buildScript.contains("BUILD_PRODUCT=\"SlackerBuddy\""), "Build script should copy the SwiftPM SlackerBuddy binary")
        try expect(buildScript.contains("CFBundleIconFile"), "Packaged app should declare an app icon")
        try expect(buildScript.contains("SlackerBuddy.icns"), "Packaged app should copy the SlackerBuddy app icon")
        try expect(FileManager.default.fileExists(atPath: "Assets/SlackerBuddyAppIcon.png"), "Expected generated app icon asset")
        try expect(FileManager.default.fileExists(atPath: "Assets/SlackerBuddyMenuBarIcon.png"), "Expected generated menu bar icon asset")
        try expect(FileManager.default.fileExists(atPath: "Assets/SlackerBuddy.icns"), "Expected generated icns asset")
    },
    TestCase(name: "active SwiftPM project is renamed to SlackerBuddy") {
        let packageSource = try String(
            contentsOf: URL(fileURLWithPath: "Package.swift"),
            encoding: .utf8
        )
        let buildScript = try String(
            contentsOf: URL(fileURLWithPath: "script/build_and_run.sh"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(packageSource.contains("name: \"SlackerBuddy\""), "Package should be named SlackerBuddy")
        try expect(packageSource.contains(".executable(name: \"SlackerBuddy\""), "Executable product should be SlackerBuddy")
        try expect(packageSource.contains(".library(name: \"SlackerBuddyCore\""), "Core library should be SlackerBuddyCore")
        try expect(packageSource.contains(".executable(name: \"SlackerBuddyTestRunner\""), "Test runner should be SlackerBuddyTestRunner")
        try expect(!packageSource.contains("MacPet"), "Active Package.swift should not contain MacPet")
        try expect(buildScript.contains("BUILD_PRODUCT=\"SlackerBuddy\""), "Build script should build the SlackerBuddy product")
        try expect(!buildScript.contains("MacPet"), "Active build script should not contain MacPet")
        try expect(windowSource.contains("window.title = \"SlackerBuddy\""), "Pet window title should use SlackerBuddy")
        try expect(FileManager.default.fileExists(atPath: "Sources/SlackerBuddy"), "Expected SlackerBuddy app source directory")
        try expect(FileManager.default.fileExists(atPath: "Sources/SlackerBuddyCore"), "Expected SlackerBuddyCore source directory")
        try expect(FileManager.default.fileExists(atPath: "Tests/SlackerBuddyTestRunner"), "Expected SlackerBuddyTestRunner directory")
    },
    TestCase(name: "legacy package targets macOS 10.13") {
        let legacyPackage = try String(
            contentsOf: URL(fileURLWithPath: "Legacy/Package.swift"),
            encoding: .utf8
        )
        let buildScript = try String(
            contentsOf: URL(fileURLWithPath: "script/build_legacy_10_13.sh"),
            encoding: .utf8
        )

        try expect(legacyPackage.contains("name: \"SlackerBuddyLegacy\""), "Legacy package should be named SlackerBuddyLegacy")
        try expect(legacyPackage.contains(".macOS(.v10_13)"), "Legacy package should target macOS 10.13")
        try expect(legacyPackage.contains(".executable(name: \"SlackerBuddyLegacy\""), "Legacy package should expose an executable product")
        try expect(buildScript.contains("MIN_SYSTEM_VERSION=\"10.13.1\""), "Legacy bundle should declare macOS 10.13.1 as its minimum system version")
        try expect(buildScript.contains("TARGET_TRIPLE=\"x86_64-apple-macosx10.13\""), "Legacy build should produce an Intel binary for High Sierra")
        try expect(buildScript.contains("MACOSX_DEPLOYMENT_TARGET=\"$MIN_SYSTEM_VERSION\""), "Legacy build should set the compiler deployment target")
        try expect(buildScript.contains("swift-stdlib-tool"), "Legacy bundle should embed Swift runtime libraries for older macOS releases")
        try expect(buildScript.contains("@executable_path/../Frameworks"), "Legacy binary should search the app bundle for embedded Swift libraries")
        try expect(buildScript.contains("dist/legacy"), "Legacy build should write to an isolated dist directory")
    },
    TestCase(name: "legacy app avoids modern macOS-only frameworks") {
        let legacySource = try String(
            contentsOf: URL(fileURLWithPath: "Legacy/Sources/SlackerBuddyLegacy/main.swift"),
            encoding: .utf8
        )

        try expect(legacySource.contains("import AppKit"), "Legacy app should use AppKit")
        try expect(!legacySource.contains("import SwiftUI"), "Legacy app should not depend on SwiftUI")
        try expect(!legacySource.contains("import Observation"), "Legacy app should not depend on Observation")
        try expect(!legacySource.contains("MenuBarExtra"), "Legacy app should avoid SwiftUI menu bar APIs")
        try expect(!legacySource.contains("NSHostingView"), "Legacy app should avoid SwiftUI hosting views")
        try expect(!legacySource.contains("UserNotifications"), "Legacy app should avoid newer notification APIs")
    },
    TestCase(name: "legacy app includes basic companion behavior") {
        let legacySource = try String(
            contentsOf: URL(fileURLWithPath: "Legacy/Sources/SlackerBuddyLegacy/main.swift"),
            encoding: .utf8
        )

        try expect(legacySource.contains("startBlinking"), "Legacy pet should blink automatically")
        try expect(legacySource.contains("randomClickAction"), "Legacy pet should react randomly to clicks")
        try expect(legacySource.contains(".runLeft") && legacySource.contains(".runRight"), "Legacy pet should have directional running feedback")
        try expect(legacySource.contains("startReminderTimer"), "Legacy pet should keep a rest reminder timer")
        try expect(legacySource.contains("Time for a break"), "Legacy pet should show rest reminder copy")
        try expect(legacySource.contains("I'm back!"), "Legacy pet should include an early-dismiss bubble button")
    },
    TestCase(name: "windows app is isolated in its own folder") {
        try expect(FileManager.default.fileExists(atPath: "Windows/package.json"), "Expected Windows Electron package")
        try expect(FileManager.default.fileExists(atPath: "Windows/src/main.js"), "Expected Windows main process source")
        try expect(FileManager.default.fileExists(atPath: "Windows/src/renderer.js"), "Expected Windows renderer source")
        try expect(FileManager.default.fileExists(atPath: "Windows/assets/SlackerBuddyAppIcon.png"), "Expected Windows app icon copy")
        try expect(FileManager.default.fileExists(atPath: "Windows/assets/SlackerBuddyTrayIcon.png"), "Expected Windows tray icon copy")
        try expect(FileManager.default.fileExists(atPath: "Windows/assets/SlackerBuddy.ico"), "Expected Windows ico packaging icon")
        try expect(FileManager.default.fileExists(atPath: "Windows/assets/fufu-spritesheet.webp"), "Expected bundled FuFu spritesheet")
        try expect(FileManager.default.fileExists(atPath: "Windows/assets/fufu-idle.png"), "Expected bundled FuFu fallback image")
    },
    TestCase(name: "windows app keeps SlackerBuddy branding and icon assets") {
        let packageSource = try String(contentsOf: URL(fileURLWithPath: "Windows/package.json"), encoding: .utf8)
        let mainSource = try String(contentsOf: URL(fileURLWithPath: "Windows/src/main.js"), encoding: .utf8)
        let readmeSource = try String(contentsOf: URL(fileURLWithPath: "Windows/README.md"), encoding: .utf8)

        try expect(packageSource.contains("\"productName\": \"SlackerBuddy\""), "Windows package should keep SlackerBuddy product name")
        try expect(packageSource.contains("\"icon\": \"assets/SlackerBuddy.ico\""), "Windows builder should use the converted existing paw icon")
        try expect(packageSource.contains("\"extraResources\""), "Windows builder should copy runtime assets outside the app asar")
        try expect(mainSource.contains("SlackerBuddyAppIcon.png"), "Windows app should load the existing app icon artwork")
        try expect(mainSource.contains("SlackerBuddyTrayIcon.png") || mainSource.contains("SlackerBuddy.ico"), "Windows app should load SlackerBuddy tray icon artwork")
        try expect(readmeSource.contains("The `.ico` file is only a Windows packaging conversion"), "Windows docs should clarify the icon is not redesigned")
    },
    TestCase(name: "windows app preserves desktop pet features") {
        let mainSource = try String(contentsOf: URL(fileURLWithPath: "Windows/src/main.js"), encoding: .utf8)
        let rendererSource = try String(contentsOf: URL(fileURLWithPath: "Windows/src/renderer.js"), encoding: .utf8)

        try expect(mainSource.contains("transparent: true"), "Windows pet window should be transparent")
        try expect(mainSource.contains("alwaysOnTop: true"), "Windows pet window should stay above other windows")
        try expect(mainSource.contains("Tray"), "Windows app should provide tray controls")
        try expect(mainSource.contains("Notification"), "Windows app should support system notifications")
        try expect(mainSource.contains(".codex\", \"pets\"") || mainSource.contains(".codex\", \"pets"), "Windows app should load PetDex pets from the user pet folder")
        try expect(mainSource.contains("displayName: \"FuFu (Built-in)\""), "Windows app should ship FuFu as a built-in pet")
        try expect(mainSource.contains("process.resourcesPath"), "Packaged Windows app should load assets from runtime resources")
        try expect(mainSource.contains("pet:ready"), "Windows pet renderer should notify main when the pet is ready to show")
        try expect(rendererSource.contains("automaticActionsEnabled"), "Windows app should preserve automatic actions setting")
        try expect(rendererSource.contains("automaticRunningEnabled"), "Windows app should preserve automatic running setting")
        try expect(rendererSource.contains("restBlockingEnabled"), "Windows app should preserve rest blocking setting")
        try expect(rendererSource.contains("waterRemindersEnabled"), "Windows app should preserve water reminders setting")
        try expect(rendererSource.contains("dragRunningLeft") && rendererSource.contains("dragRunningRight"), "Windows app should preserve directional drag feedback")
        try expect(rendererSource.contains("verifySpriteImage") && rendererSource.contains("drawFallbackPet"), "Windows pet should fall back to bundled FuFu if spritesheet loading fails")
        try expect(rendererSource.contains("language") && rendererSource.contains("chinese") && rendererSource.contains("english"), "Windows app should preserve Chinese and English settings")
    },
    TestCase(name: "app uses provided SlackerBuddy icon assets") {
        let repoAppIcon = try Data(contentsOf: URL(fileURLWithPath: "Assets/SlackerBuddyAppIcon.png"))
        let providedAppIcon = try Data(contentsOf: URL(fileURLWithPath: "/Users/xyue/Pictures/SlackerBuddy App Icon.png"))
        let repoMenuIcon = try Data(contentsOf: URL(fileURLWithPath: "Assets/SlackerBuddyMenuBarIcon.png"))
        let providedMenuIcon = try Data(contentsOf: URL(fileURLWithPath: "/Users/xyue/Pictures/SlackerBuddy Touch Bar Icon.png"))
        let appIconSize = try imagePixelSize(at: "Assets/SlackerBuddyAppIcon.png")
        let menuIconSize = try imagePixelSize(at: "Assets/SlackerBuddyMenuBarIcon.png")
        let appIconVisibleBounds = try visibleImageBounds(at: "Assets/SlackerBuddyAppIcon.png")

        try expect(repoAppIcon != providedAppIcon, "Expected app icon to be cropped/resized from the user-provided reference")
        try expect(repoMenuIcon != providedMenuIcon, "Expected menu bar icon to be cropped/resized from the user-provided reference")
        try expect(appIconSize.width == appIconSize.height && appIconSize.width >= 512, "Expected app icon to be a large square asset")
        try expect(Double(appIconVisibleBounds.width) / Double(appIconSize.width) >= 0.68, "Expected app icon paw to fill more horizontal space")
        try expect(menuIconSize.width == menuIconSize.height && menuIconSize.width >= 128, "Expected menu bar icon to be a square template-ready asset")
    },
    TestCase(name: "release website introduces SlackerBuddy and links the DMG") {
        let siteURL = URL(fileURLWithPath: "docs/site/index.html")
        let siteSource = try String(contentsOf: siteURL, encoding: .utf8)

        try expect(siteSource.contains("SlackerBuddy"), "Release page should introduce SlackerBuddy")
        try expect(siteSource.contains("FuFu"), "Release page should introduce the FuFu pet")
        try expect(siteSource.contains("downloads/SlackerBuddy.dmg"), "Release page should link the distributable DMG")
        try expect(siteSource.contains("downloads/SlackerBuddyLegacy-10.13.dmg"), "Release page should link the macOS 10.13.1 legacy DMG")
        try expect(siteSource.contains("macOS 10.13.1") && siteSource.contains("High Sierra"), "Release page should explain the legacy High Sierra build")
        try expect(siteSource.contains("downloads/SlackerBuddy-Windows-Setup-1.0.0.exe"), "Release page should link the Windows installer")
        try expect(siteSource.contains("downloads/SlackerBuddy-Windows-Portable-1.0.0.exe"), "Release page should link the Windows portable build")
        try expect(siteSource.contains("Windows 10") || siteSource.contains("Windows 安装器"), "Release page should explain the Windows build")
        try expect(siteSource.contains("docs/site/assets/fufu-idle.png") || FileManager.default.fileExists(atPath: "docs/site/assets/fufu-idle.png"), "Release page should have a pet preview asset")
        try expect(FileManager.default.fileExists(atPath: "docs/site/assets/slackerbuddy-app-icon.png"), "Release page should copy the app icon asset")
        try expect(FileManager.default.fileExists(atPath: "docs/site/downloads/SlackerBuddyLegacy-10.13.dmg"), "Release page should include the legacy DMG asset")
        try expect(FileManager.default.fileExists(atPath: "docs/site/downloads/SlackerBuddy-Windows-Setup-1.0.0.exe"), "Release page should include the Windows installer asset")
        try expect(FileManager.default.fileExists(atPath: "docs/site/downloads/SlackerBuddy-Windows-Portable-1.0.0.exe"), "Release page should include the Windows portable asset")
    },
    TestCase(name: "packaged app bundle is signed after resources are copied") {
        let buildScript = try String(
            contentsOf: URL(fileURLWithPath: "script/build_and_run.sh"),
            encoding: .utf8
        )
        guard let resourceCopyRange = buildScript.range(of: "cp \"$ROOT_DIR/Assets/SlackerBuddyMenuBarIcon.png\"") else {
            throw TestFailure.failed("Build script should copy the menu bar icon resource")
        }
        guard let signingRange = buildScript.range(of: "codesign --force --deep --sign - \"$APP_BUNDLE\"") else {
            throw TestFailure.failed("Build script should ad-hoc sign the final app bundle")
        }

        try expect(resourceCopyRange.upperBound < signingRange.lowerBound, "Final app bundle signing should happen after resources are copied")
    },
    TestCase(name: "release website explains first launch for ad-hoc distribution") {
        let siteURL = URL(fileURLWithPath: "docs/site/index.html")
        let siteSource = try String(contentsOf: siteURL, encoding: .utf8)

        try expect(siteSource.contains("Control") || siteSource.contains("右键"), "Release page should explain the first launch gesture for an ad-hoc signed app")
        try expect(siteSource.contains("打开"), "Release page should tell users how to open the app")
    },
    TestCase(name: "release website includes detailed Gatekeeper walkthrough") {
        let siteURL = URL(fileURLWithPath: "docs/site/index.html")
        let siteSource = try String(contentsOf: siteURL, encoding: .utf8)

        try expect(siteSource.contains("Privacy & Security") || siteSource.contains("Privacy &amp; Security"), "Release page should name the macOS Privacy & Security settings page")
        try expect(siteSource.contains("Open Anyway"), "Release page should mention the Open Anyway button")
        try expect(siteSource.contains("问号"), "Release page should explain the help button in the security dialog")
        try expect(siteSource.contains("assets/install-control-open.svg"), "Release page should show the Control-click illustration")
        try expect(siteSource.contains("assets/install-privacy-security.svg"), "Release page should show the Privacy & Security illustration")
        try expect(siteSource.contains("assets/install-open-anyway.svg"), "Release page should show the Open Anyway illustration")
        try expect(FileManager.default.fileExists(atPath: "docs/site/assets/install-control-open.svg"), "Expected Control-click install illustration asset")
        try expect(FileManager.default.fileExists(atPath: "docs/site/assets/install-privacy-security.svg"), "Expected Privacy & Security install illustration asset")
        try expect(FileManager.default.fileExists(atPath: "docs/site/assets/install-open-anyway.svg"), "Expected Open Anyway install illustration asset")
    },
    TestCase(name: "release website explains PetDex pet installation") {
        let siteURL = URL(fileURLWithPath: "docs/site/index.html")
        let siteSource = try String(contentsOf: siteURL, encoding: .utf8)

        try expect(siteSource.contains("PetDex"), "Release page should explain PetDex support")
        try expect(siteSource.contains("petdex.crafter.run"), "Release page should link to PetDex")
        try expect(siteSource.contains("~/.codex/pets"), "Release page should show where PetDex pets are installed")
        try expect(siteSource.contains("设置") && siteSource.contains("宠物"), "Release page should tell users to choose pets in settings")
        try expect(siteSource.contains("下载宠物"), "Release page should explain downloading pets")
    },
    TestCase(name: "release website defaults to English and offers language switcher") {
        let siteURL = URL(fileURLWithPath: "docs/site/index.html")
        let siteSource = try String(contentsOf: siteURL, encoding: .utf8)

        try expect(siteSource.contains("<html lang=\"en\">"), "Release page should default to English")
        try expect(siteSource.contains("class=\"language-switcher\""), "Release page should show a top-right language switcher")
        try expect(siteSource.contains("data-language-option=\"en\""), "Language switcher should include English")
        try expect(siteSource.contains("data-language-option=\"zh-CN\""), "Language switcher should include Chinese")
        try expect(siteSource.contains("const translations"), "Release page should include static translations")
        try expect(siteSource.contains("\"zh-CN\""), "Release page should include Chinese translations")
        try expect(siteSource.contains("A tiny Mac cat"), "Default hero copy should be English")
    },
    TestCase(name: "settings refreshes Petdex catalog when opened") {
        let macPetAppSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/SlackerBuddyApp.swift"),
            encoding: .utf8
        )

        try expect(macPetAppSource.contains("availablePets: runtime.availablePets"), "Settings picker should use runtime Petdex pets")
        try expect(macPetAppSource.contains(".onAppear"), "Settings should refresh when the settings scene appears")
        try expect(macPetAppSource.contains("runtime.refreshPetCatalog()"), "Settings should refresh Petdex catalog when opened")
    },
    TestCase(name: "runtime normalizes removed selected Petdex pet") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("settings.updateSelectedPetID(PetAsset.builtinID)"), "Refreshing Petdex should persist builtin selection when saved pet is gone")
    },
    TestCase(name: "runtime refreshes visible pet window after Petdex refresh changes selection") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("let previousSelectedPetID = selectedPetAsset.id"), "Runtime should capture selected pet before catalog refresh")
        try expect(appRuntimeSource.contains("if selectedPetAsset.id != previousSelectedPetID"), "Runtime should detect selected pet changes after catalog refresh")
        try expect(appRuntimeSource.contains("refreshPetWindowIfNeeded()"), "Runtime should refresh visible pet window after selected pet changes")
    },
    TestCase(name: "runtime does not reshow hidden pet during refresh") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("petWindowController.window?.isVisible == true"), "Runtime should refresh pet window only when the pet window is visible")
    },
    TestCase(name: "settings visible copy is fully localized") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let localizedStringsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddyCore/Localization/LocalizedStrings.swift"),
            encoding: .utf8
        )

        try expect(!settingsSource.contains(") min\""), "Settings duration labels should not hard-code English min suffix")
        try expect(!settingsSource.contains("return \"System\""), "System language label should be localized")
        try expect(localizedStringsSource.contains("case minuteSuffix"), "Localized strings should include minute suffix")
        try expect(localizedStringsSource.contains("case systemLanguageOption"), "Localized strings should include system language option")
    },
    TestCase(name: "settings exposes reminder and automatic action controls with custom time input") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/SettingsView.swift"),
            encoding: .utf8
        )

        try expect(settingsSource.contains("Toggle(strings.text(.enableRestReminders)"), "Settings should expose rest reminder toggle")
        try expect(settingsSource.contains("TimeValueControl("), "Settings should use reusable custom time input controls")
        try expect(settingsSource.contains("binding: reminderIntervalMinutes"), "Settings should expose rest interval custom input")
        try expect(settingsSource.contains("Toggle(strings.text(.restBlockingEnabled)"), "Settings should expose blocking toggle")
        try expect(settingsSource.contains("binding: restBlockingDurationSeconds"), "Settings should expose blocking duration custom input")
        try expect(settingsSource.contains("Stepper(value: restBlockingScalePercent"), "Settings should expose blocking scale stepper")
        try expect(settingsSource.contains("Toggle(strings.text(.enableWaterReminders)"), "Settings should expose water toggle")
        try expect(settingsSource.contains("binding: waterIntervalMinutes"), "Settings should expose water interval custom input")
        try expect(!settingsSource.contains("sleepDelayMinutes"), "Settings should remove the sleep delay control")
        try expect(settingsSource.contains("binding: bubbleDurationSeconds"), "Settings should expose bubble duration custom input")
        try expect(settingsSource.contains("Toggle(strings.text(.enableAutomaticActions)"), "Settings should expose automatic actions toggle")
        try expect(settingsSource.contains("binding: automaticActionIntervalMinutes"), "Settings should expose automatic frequency custom input")
        try expect(settingsSource.contains("Toggle(strings.text(.enableAutomaticRunning)"), "Settings should expose automatic running toggle")
        try expect(settingsSource.contains("Picker(strings.text(.automaticRunDirection)"), "Settings should expose automatic running direction choices")
        try expect(settingsSource.contains("TextField"), "Settings time rows should allow direct typed custom values")
    },
    TestCase(name: "settings shows system notification feedback") {
        let settingsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/SettingsView.swift"),
            encoding: .utf8
        )
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let macPetAppSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/SlackerBuddyApp.swift"),
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
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Animation/PetSpriteSheetView.swift"),
            encoding: .utf8
        )

        try expect(spriteViewSource.contains("PetSpriteSheetFrameCache"), "Sprite renderer should use a frame cache")
        try expect(!spriteViewSource.contains("NSImage(contentsOf: spriteSheetURL)"), "Sprite renderer should not decode the atlas directly on each frame")
    },
    TestCase(name: "runtime centralizes rest and water reminder priority") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("handleDueReminders()"), "Runtime should centralize rest and water priority")
        try expect(appRuntimeSource.contains("restReminderScheduler.tick()"), "Runtime should tick rest scheduler")
        try expect(appRuntimeSource.contains("waterReminderScheduler.tick()"), "Runtime should tick water scheduler")
        try expect(appRuntimeSource.contains("if restReminderScheduler.isActive"), "Rest reminder should take priority")
    },
    TestCase(name: "runtime wires automatic scheduler and blocking overlay") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
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
    TestCase(name: "blocking overlay scales visible pet content within screen bounds") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("PetDisplayState"), "Runtime should own shared display state for blocking scale")
        try expect(appRuntimeSource.contains("displayState.petScaleOverride"), "Runtime should set a blocking pet scale override")
        try expect(petViewSource.contains("displayState.effectivePetScale"), "PetView should render with the blocking scale override")
        try expect(windowSource.contains("blockingFrame(scalePercent:"), "Window controller should calculate a bounded blocking frame")
        try expect(windowSource.contains("visibleFrame.width") && windowSource.contains("visibleFrame.height"), "Blocking frame calculation should constrain to visible screen bounds")
        try expect(windowSource.contains("return (frame, effectiveScale)") || windowSource.contains("-> (frame: NSRect, effectiveScale: Double)"), "Window controller should return the effective content scale it applied")
    },
    TestCase(name: "pet view delegates reminder dismissal to runtime") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )

        try expect(petViewSource.contains("private let onDismissReminder: () -> Void"), "PetView should receive a runtime-owned reminder dismissal callback")
        try expect(petViewSource.contains("onDismissReminder()"), "PetView should invoke the runtime dismissal callback")
        try expect(!petViewSource.contains("scheduler.dismissActiveReminder()"), "PetView should not dismiss only the legacy rest scheduler")
        try expect(appRuntimeSource.contains("onDismissReminder: { [weak self] in"), "Runtime should pass a kind-aware dismissal callback into PetView")
        try expect(appRuntimeSource.contains("self?.dismissActiveReminder()"), "Runtime dismissal callback should route through active reminder kind handling")
    },
    TestCase(name: "rest blocking bubble exposes return button") {
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )
        let bubbleViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/BubbleView.swift"),
            encoding: .utf8
        )

        try expect(petViewSource.contains("strings.text(.restBlockingReturnButton)"), "Rest reminder bubble should use the localized return button label")
        try expect(bubbleViewSource.contains("buttonTitle"), "Bubble view should support an optional interactive button title")
        try expect(bubbleViewSource.contains("Button(action: onDismiss)"), "Bubble view should provide a clickable dismissal button")
    },
    TestCase(name: "blocking overlay frame changes do not report movement") {
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
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
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
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
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("guard stateMachine.activeReminderKind == nil else"), "Runtime should not tick reminder schedulers while another reminder is active")
        try expect(appRuntimeSource.contains("tickReminderSchedulers()"), "Runtime should separate reminder ticking from automatic action ticking")
        try expect(appRuntimeSource.contains("restReminderScheduler.stop()"), "Disabling rest reminders should stop the legacy rest scheduler")
    },
    TestCase(name: "runtime completes automatic action animations") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("stateMachine.state == .automaticBlink"), "Runtime should complete automatic blink animations")
        try expect(appRuntimeSource.contains("stateMachine.state == .automaticRunningLeft"), "Runtime should complete automatic left running animations")
        try expect(appRuntimeSource.contains("stateMachine.state == .automaticRunningRight"), "Runtime should complete automatic right running animations")
    },
    TestCase(name: "runtime gives immediate automatic action and running feedback") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(appRuntimeSource.contains("triggerAutomaticActionFeedback()"), "Runtime should trigger automatic feedback immediately when enabled")
        try expect(appRuntimeSource.contains("performAutomaticRun(direction:"), "Runtime should move the pet during automatic running")
        try expect(appRuntimeSource.contains("randomExpressiveAction()"), "Runtime should choose random expressive actions when automatic actions are enabled")
        try expect(appRuntimeSource.contains("automaticRunDirectionMode"), "Runtime should honor automatic running direction mode")
        try expect(windowSource.contains("moveHorizontally(points:"), "Window controller should expose programmatic horizontal movement")
        try expect(windowSource.contains("performProgrammaticFrameChange"), "Automatic movement should be programmatic and not count as user drag")
    },
    TestCase(name: "pet tap delegates random expressive feedback to runtime") {
        let appRuntimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )

        try expect(petViewSource.contains("private let onPetTap: () -> Void"), "PetView should delegate non-reminder taps to runtime")
        try expect(petViewSource.contains("onPetTap()"), "PetView should call runtime tap handler")
        try expect(appRuntimeSource.contains("func handlePetTap()"), "Runtime should own random tap behavior")
        try expect(appRuntimeSource.contains("stateMachine.handle(.expressiveAction(randomExpressiveAction()))"), "Runtime should randomize tap expressive actions")
    },
    TestCase(name: "Petdex directional sprites are not double-flipped") {
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )
        let windowSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Windowing/PetWindowController.swift"),
            encoding: .utf8
        )

        try expect(!petViewSource.contains("petContent(frameName: frame)\n                    .scaleEffect"), "Petdex sprites should not be globally flipped after row mapping")
        try expect(petViewSource.contains("PixelCatPlaceholderView(frameName: frameName)\n                .scaleEffect"), "Only the placeholder should mirror left-facing frames")
        try expect(windowSource.contains("horizontalDelta"), "Window movement direction should be based on a horizontal delta")
        try expect(!windowSource.contains("guard let oldFrame else {\n            return .right"), "Unknown movement direction should not default every drag to right")
    },
    TestCase(name: "settings menu opens frontmost on current desktop") {
        let appSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/SlackerBuddyApp.swift"),
            encoding: .utf8
        )
        let runtimeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/App/AppRuntime.swift"),
            encoding: .utf8
        )

        try expect(!appSource.contains("SettingsLink"), "Menu bar settings should use a controlled settings opener instead of SettingsLink")
        try expect(appSource.contains("@Environment(\\.openSettings)"), "Menu bar settings should use SwiftUI openSettings action")
        try expect(appSource.contains("openSettings()"), "Menu bar settings should open the Settings scene through SwiftUI")
        try expect(appSource.contains("runtime.focusSettingsWindow()"), "Menu bar settings should ask runtime to foreground the opened window")
        try expect(runtimeSource.contains("func focusSettingsWindow()"), "Runtime should expose settings foregrounding without owning Settings scene creation")
        try expect(!runtimeSource.contains("showSettingsWindow:"), "Runtime should not rely on an unreliable AppKit showSettingsWindow selector")
        try expect(runtimeSource.contains("NSApp.activate(ignoringOtherApps: true)"), "Settings opener should activate the app")
        try expect(runtimeSource.contains(".moveToActiveSpace"), "Settings window should move to the active desktop")
        try expect(runtimeSource.contains("orderFrontRegardless()"), "Settings window should appear above other apps")
        try expect(runtimeSource.contains("let originalLevel = window.level"), "Settings opener should capture the original window level")
        try expect(runtimeSource.contains("let originalCollectionBehavior = window.collectionBehavior"), "Settings opener should capture the original collection behavior")
        try expect(runtimeSource.contains("restoreSettingsWindowLevel"), "Settings opener should restore temporary floating level")
    },
    TestCase(name: "sleep delay preference is removed") {
        let preferenceSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddyCore/Models/PetPreferences.swift"),
            encoding: .utf8
        )
        let storeSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddyCore/Stores/SettingsStore.swift"),
            encoding: .utf8
        )
        let localizedStringsSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddyCore/Localization/LocalizedStrings.swift"),
            encoding: .utf8
        )

        try expect(!preferenceSource.contains("sleepDelayMinutes"), "PetPreferences should not expose sleep delay")
        try expect(!storeSource.contains("sleepDelayMinutes"), "SettingsStore should not persist sleep delay")
        try expect(!localizedStringsSource.contains("sleepDelayLabel"), "Localization should not expose sleep delay")
    },
    TestCase(name: "pet view auto-hides reminder bubble without dismissing reminder") {
        let petViewSource = try String(
            contentsOf: URL(fileURLWithPath: "Sources/SlackerBuddy/Views/PetView.swift"),
            encoding: .utf8
        )

        try expect(petViewSource.contains("bubbleDurationSeconds"), "PetView should use configured bubble duration")
        try expect(petViewSource.contains("Task.sleep"), "PetView should auto-hide bubbles after a delay")
        try expect(petViewSource.contains("isBubbleVisible"), "PetView should hide bubble without dismissing reminder")
    }
]

private func imagePixelSize(at path: String) throws -> (width: Int, height: Int) {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? Int,
          let height = properties[kCGImagePropertyPixelHeight] as? Int else {
        throw TestFailure.failed("Could not read image size for \(path)")
    }

    return (width, height)
}

private func visibleImageBounds(at path: String) throws -> (width: Int, height: Int) {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
          let dataProvider = image.dataProvider,
          let data = dataProvider.data,
          let bytes = CFDataGetBytePtr(data) else {
        throw TestFailure.failed("Could not read image pixels for \(path)")
    }

    let width = image.width
    let height = image.height
    let bytesPerRow = image.bytesPerRow
    let bitsPerPixel = image.bitsPerPixel
    let bytesPerPixel = bitsPerPixel / 8
    guard bytesPerPixel >= 4 else {
        throw TestFailure.failed("Expected RGBA-like image for \(path)")
    }

    var minX = width
    var minY = height
    var maxX = 0
    var maxY = 0
    for y in 0..<height {
        for x in 0..<width {
            let offset = y * bytesPerRow + x * bytesPerPixel
            let alpha = bytes[offset + 3]
            if alpha > 24 {
                minX = min(minX, x)
                minY = min(minY, y)
                maxX = max(maxX, x)
                maxY = max(maxY, y)
            }
        }
    }

    guard minX <= maxX, minY <= maxY else {
        throw TestFailure.failed("Expected visible pixels for \(path)")
    }
    return (maxX - minX + 1, maxY - minY + 1)
}

import AppKit
import SwiftUI

@main
struct MacPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var runtime: AppRuntime

    init() {
        let runtime = AppRuntime()
        _runtime = State(initialValue: runtime)

        Task { @MainActor in
            runtime.start()
        }
    }

    var body: some Scene {
        MenuBarExtra("Mac Pet", systemImage: "pawprint.fill") {
            Button(runtime.localizedStrings.text(.showPetMenu)) {
                runtime.showPet()
            }

            Button(runtime.localizedStrings.text(.hidePetMenu)) {
                runtime.hidePet()
            }

            Divider()

            Toggle(runtime.localizedStrings.text(.lowerDistractionMode), isOn: lowerDistractionMode)

            Divider()

            SettingsLink {
                Text(runtime.localizedStrings.text(.settingsTitle))
            }

            Divider()

            Button(runtime.localizedStrings.text(.quitMenu)) {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                settings: runtime.settings,
                availablePets: runtime.availablePets,
                onPetScaleChanged: { runtime.updatePetScale($0) },
                onReminderIntervalChanged: { runtime.updateReminderInterval(minutes: $0) },
                onRestRemindersEnabledChanged: { runtime.updateRestRemindersEnabled($0) },
                onRestBlockingEnabledChanged: { runtime.updateRestBlockingEnabled($0) },
                onRestBlockingDurationChanged: { runtime.updateRestBlockingDuration(seconds: $0) },
                onRestBlockingScaleChanged: { runtime.updateRestBlockingScale(percent: $0) },
                onWaterRemindersEnabledChanged: { runtime.updateWaterRemindersEnabled($0) },
                onWaterIntervalChanged: { runtime.updateWaterInterval(minutes: $0) },
                onBubbleDurationChanged: { runtime.updateBubbleDuration(seconds: $0) },
                onAutomaticActionsEnabledChanged: { runtime.updateAutomaticActionsEnabled($0) },
                onAutomaticActionIntervalChanged: { runtime.updateAutomaticActionInterval(minutes: $0) },
                onAutomaticRunningEnabledChanged: { runtime.updateAutomaticRunningEnabled($0) },
                onSystemNotificationsEnabledChanged: { runtime.updateSystemNotificationsEnabled($0) },
                onLanguageChanged: { runtime.updateLanguage($0) },
                onSelectedPetChanged: { runtime.updateSelectedPet($0) },
                onResetPetPosition: { runtime.resetPetPosition() }
            )
            .onAppear {
                runtime.refreshPetCatalog()
            }
        }
    }

    private var lowerDistractionMode: Binding<Bool> {
        Binding(
            get: { runtime.settings.preferences.lowerDistractionMode },
            set: { runtime.settings.updateLowerDistractionMode($0) }
        )
    }
}

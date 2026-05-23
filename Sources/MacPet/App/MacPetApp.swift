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
            Button("Show Pet") {
                runtime.showPet()
            }

            Button("Hide Pet") {
                runtime.hidePet()
            }

            Divider()

            Toggle("Lower Distraction", isOn: lowerDistractionMode)

            Divider()

            SettingsLink()

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView(
                settings: runtime.settings,
                onPetScaleChanged: { runtime.updatePetScale($0) },
                onReminderIntervalChanged: { runtime.updateReminderInterval(minutes: $0) },
                onSystemNotificationsEnabledChanged: { runtime.updateSystemNotificationsEnabled($0) }
            )
        }
    }

    private var lowerDistractionMode: Binding<Bool> {
        Binding(
            get: { runtime.settings.preferences.lowerDistractionMode },
            set: { runtime.settings.updateLowerDistractionMode($0) }
        )
    }
}

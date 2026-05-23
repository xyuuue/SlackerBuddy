import SwiftUI
import MacPetCore

@main
struct MacPetApp: App {
    @State private var settings = SettingsStore()
    @State private var stateMachine = PetStateMachine()
    @State private var scheduler = ReminderScheduler()

    var body: some Scene {
        WindowGroup("Mac Pet") {
            PetView(
                settings: settings,
                stateMachine: stateMachine,
                scheduler: scheduler
            )
        }

        Settings {
            SettingsView(settings: settings)
        }
    }
}

import Observation
import SwiftUI
import MacPetCore

public struct SettingsView: View {
    @Bindable private var settings: SettingsStore
    private let onPetScaleChanged: ((Double) -> Void)?
    private let onReminderIntervalChanged: ((Int) -> Void)?
    private let onSystemNotificationsEnabledChanged: ((Bool) -> Void)?

    public init(
        settings: SettingsStore,
        onPetScaleChanged: ((Double) -> Void)? = nil,
        onReminderIntervalChanged: ((Int) -> Void)? = nil,
        onSystemNotificationsEnabledChanged: ((Bool) -> Void)? = nil
    ) {
        self.settings = settings
        self.onPetScaleChanged = onPetScaleChanged
        self.onReminderIntervalChanged = onReminderIntervalChanged
        self.onSystemNotificationsEnabledChanged = onSystemNotificationsEnabledChanged
    }

    public var body: some View {
        Form {
            Section("Pet") {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Size")
                        Spacer()
                        Text(settings.preferences.petScale, format: .number.precision(.fractionLength(1)))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: petScale, in: 0.5...3.0, step: 0.1)
                }

                Toggle("Show pet on launch", isOn: showPetOnLaunch)
                Toggle("Lower-distraction mode", isOn: lowerDistractionMode)
            }

            Section("Reminders") {
                Stepper(value: reminderIntervalMinutes, in: 1...240, step: 1) {
                    Text("Reminder interval: \(settings.preferences.reminderIntervalMinutes) min")
                }

                Stepper(value: sleepDelayMinutes, in: 1...240, step: 1) {
                    Text("Sleep delay: \(settings.preferences.sleepDelayMinutes) min")
                }

                Toggle("System notifications", isOn: systemNotificationsEnabled)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }

    private var petScale: Binding<Double> {
        Binding(
            get: { settings.preferences.petScale },
            set: { value in
                if let onPetScaleChanged {
                    onPetScaleChanged(value)
                } else {
                    settings.updatePetScale(value)
                }
            }
        )
    }

    private var showPetOnLaunch: Binding<Bool> {
        Binding(
            get: { settings.preferences.showPetOnLaunch },
            set: { settings.updateShowPetOnLaunch($0) }
        )
    }

    private var lowerDistractionMode: Binding<Bool> {
        Binding(
            get: { settings.preferences.lowerDistractionMode },
            set: { settings.updateLowerDistractionMode($0) }
        )
    }

    private var reminderIntervalMinutes: Binding<Int> {
        Binding(
            get: { settings.preferences.reminderIntervalMinutes },
            set: { value in
                if let onReminderIntervalChanged {
                    onReminderIntervalChanged(value)
                } else {
                    settings.updateReminderInterval(minutes: value)
                }
            }
        )
    }

    private var sleepDelayMinutes: Binding<Int> {
        Binding(
            get: { settings.preferences.sleepDelayMinutes },
            set: { settings.updateSleepDelay(minutes: $0) }
        )
    }

    private var systemNotificationsEnabled: Binding<Bool> {
        Binding(
            get: { settings.preferences.systemNotificationsEnabled },
            set: { value in
                if let onSystemNotificationsEnabledChanged {
                    onSystemNotificationsEnabledChanged(value)
                } else {
                    settings.updateSystemNotificationsEnabled(value)
                }
            }
        )
    }
}

import Observation
import SwiftUI
import MacPetCore

public struct SettingsView: View {
    @Bindable private var settings: SettingsStore
    private let availablePets: [PetAsset]
    private let onPetScaleChanged: ((Double) -> Void)?
    private let onReminderIntervalChanged: ((Int) -> Void)?
    private let onSystemNotificationsEnabledChanged: ((Bool) -> Void)?
    private let onLanguageChanged: ((AppLanguage) -> Void)?
    private let onSelectedPetChanged: ((String) -> Void)?
    private let onResetPetPosition: (() -> Void)?

    public init(
        settings: SettingsStore,
        availablePets: [PetAsset],
        onPetScaleChanged: ((Double) -> Void)? = nil,
        onReminderIntervalChanged: ((Int) -> Void)? = nil,
        onSystemNotificationsEnabledChanged: ((Bool) -> Void)? = nil,
        onLanguageChanged: ((AppLanguage) -> Void)? = nil,
        onSelectedPetChanged: ((String) -> Void)? = nil,
        onResetPetPosition: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.availablePets = availablePets
        self.onPetScaleChanged = onPetScaleChanged
        self.onReminderIntervalChanged = onReminderIntervalChanged
        self.onSystemNotificationsEnabledChanged = onSystemNotificationsEnabledChanged
        self.onLanguageChanged = onLanguageChanged
        self.onSelectedPetChanged = onSelectedPetChanged
        self.onResetPetPosition = onResetPetPosition
    }

    public var body: some View {
        Form {
            Section(strings.text(.petSectionTitle)) {
                Picker(strings.text(.languageLabel), selection: language) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(languageName(language)).tag(language)
                    }
                }

                Picker(strings.text(.petLabel), selection: selectedPetID) {
                    ForEach(availablePets) { pet in
                        Text(pet.displayName).tag(pet.id)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(strings.text(.petSizeLabel))
                        Spacer()
                        Text(settings.preferences.petScale, format: .number.precision(.fractionLength(1)))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: petScale, in: 0.5...3.0, step: 0.1)
                }

                Toggle(strings.text(.showPetOnLaunch), isOn: showPetOnLaunch)
                Toggle(strings.text(.lowerDistractionMode), isOn: lowerDistractionMode)

                Button(strings.text(.resetPetPosition)) {
                    onResetPetPosition?()
                }
            }

            Section(strings.text(.remindersSectionTitle)) {
                Stepper(value: reminderIntervalMinutes, in: 1...240, step: 1) {
                    Text("\(strings.text(.reminderIntervalLabel)): \(settings.preferences.reminderIntervalMinutes) min")
                }

                Stepper(value: sleepDelayMinutes, in: 1...240, step: 1) {
                    Text("\(strings.text(.sleepDelayLabel)): \(settings.preferences.sleepDelayMinutes) min")
                }

                Toggle(strings.text(.systemNotifications), isOn: systemNotificationsEnabled)
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

    private var language: Binding<AppLanguage> {
        Binding(
            get: { settings.preferences.language },
            set: { value in
                if let onLanguageChanged {
                    onLanguageChanged(value)
                } else {
                    settings.updateLanguage(value)
                }
            }
        )
    }

    private var selectedPetID: Binding<String> {
        Binding(
            get: { settings.preferences.selectedPetID },
            set: { value in
                if let onSelectedPetChanged {
                    onSelectedPetChanged(value)
                } else {
                    settings.updateSelectedPetID(value)
                }
            }
        )
    }

    private var strings: LocalizedStrings {
        LocalizedStrings(language: settings.preferences.language)
    }

    private func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return "System"
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }
}

import Observation
import SwiftUI
import SlackerBuddyCore

public struct SettingsView: View {
    @Bindable private var settings: SettingsStore
    private let availablePets: [PetAsset]
    private let notificationPermissionStatus: NotificationPermissionStatus
    private let onPetScaleChanged: ((Double) -> Void)?
    private let onReminderIntervalChanged: ((Int) -> Void)?
    private let onRestRemindersEnabledChanged: ((Bool) -> Void)?
    private let onRestBlockingEnabledChanged: ((Bool) -> Void)?
    private let onRestBlockingDurationChanged: ((Int) -> Void)?
    private let onRestBlockingScaleChanged: ((Int) -> Void)?
    private let onWaterRemindersEnabledChanged: ((Bool) -> Void)?
    private let onWaterIntervalChanged: ((Int) -> Void)?
    private let onBubbleDurationChanged: ((Int) -> Void)?
    private let onAutomaticActionsEnabledChanged: ((Bool) -> Void)?
    private let onAutomaticActionIntervalChanged: ((Int) -> Void)?
    private let onAutomaticRunningEnabledChanged: ((Bool) -> Void)?
    private let onAutomaticRunDirectionModeChanged: ((AutomaticRunDirectionMode) -> Void)?
    private let onSystemNotificationsEnabledChanged: ((Bool) -> Void)?
    private let onLanguageChanged: ((AppLanguage) -> Void)?
    private let onSelectedPetChanged: ((String) -> Void)?
    private let onResetPetPosition: (() -> Void)?

    public init(
        settings: SettingsStore,
        availablePets: [PetAsset],
        notificationPermissionStatus: NotificationPermissionStatus = .off,
        onPetScaleChanged: ((Double) -> Void)? = nil,
        onReminderIntervalChanged: ((Int) -> Void)? = nil,
        onRestRemindersEnabledChanged: ((Bool) -> Void)? = nil,
        onRestBlockingEnabledChanged: ((Bool) -> Void)? = nil,
        onRestBlockingDurationChanged: ((Int) -> Void)? = nil,
        onRestBlockingScaleChanged: ((Int) -> Void)? = nil,
        onWaterRemindersEnabledChanged: ((Bool) -> Void)? = nil,
        onWaterIntervalChanged: ((Int) -> Void)? = nil,
        onBubbleDurationChanged: ((Int) -> Void)? = nil,
        onAutomaticActionsEnabledChanged: ((Bool) -> Void)? = nil,
        onAutomaticActionIntervalChanged: ((Int) -> Void)? = nil,
        onAutomaticRunningEnabledChanged: ((Bool) -> Void)? = nil,
        onAutomaticRunDirectionModeChanged: ((AutomaticRunDirectionMode) -> Void)? = nil,
        onSystemNotificationsEnabledChanged: ((Bool) -> Void)? = nil,
        onLanguageChanged: ((AppLanguage) -> Void)? = nil,
        onSelectedPetChanged: ((String) -> Void)? = nil,
        onResetPetPosition: (() -> Void)? = nil
    ) {
        self.settings = settings
        self.availablePets = availablePets
        self.notificationPermissionStatus = notificationPermissionStatus
        self.onPetScaleChanged = onPetScaleChanged
        self.onReminderIntervalChanged = onReminderIntervalChanged
        self.onRestRemindersEnabledChanged = onRestRemindersEnabledChanged
        self.onRestBlockingEnabledChanged = onRestBlockingEnabledChanged
        self.onRestBlockingDurationChanged = onRestBlockingDurationChanged
        self.onRestBlockingScaleChanged = onRestBlockingScaleChanged
        self.onWaterRemindersEnabledChanged = onWaterRemindersEnabledChanged
        self.onWaterIntervalChanged = onWaterIntervalChanged
        self.onBubbleDurationChanged = onBubbleDurationChanged
        self.onAutomaticActionsEnabledChanged = onAutomaticActionsEnabledChanged
        self.onAutomaticActionIntervalChanged = onAutomaticActionIntervalChanged
        self.onAutomaticRunningEnabledChanged = onAutomaticRunningEnabledChanged
        self.onAutomaticRunDirectionModeChanged = onAutomaticRunDirectionModeChanged
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
                Toggle(strings.text(.enableRestReminders), isOn: restRemindersEnabled)

                TimeValueControl(
                    title: strings.text(.reminderIntervalLabel),
                    binding: reminderIntervalMinutes,
                    range: 1...240,
                    unit: strings.text(.minuteSuffix)
                )

                Toggle(strings.text(.restBlockingEnabled), isOn: restBlockingEnabled)

                TimeValueControl(
                    title: strings.text(.restBlockingDuration),
                    binding: restBlockingDurationSeconds,
                    range: 1...300,
                    unit: strings.text(.secondsSuffix)
                )

                Stepper(value: restBlockingScalePercent, in: 10...90, step: 5) {
                    Text("\(strings.text(.restBlockingScale)): \(settings.preferences.restBlockingScalePercent) \(strings.text(.percentSuffix))")
                }

                Toggle(strings.text(.enableWaterReminders), isOn: waterRemindersEnabled)

                TimeValueControl(
                    title: strings.text(.waterIntervalLabel),
                    binding: waterIntervalMinutes,
                    range: 1...480,
                    unit: strings.text(.minuteSuffix)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Toggle(strings.text(.systemNotifications), isOn: systemNotificationsEnabled)
                    Text(notificationStatusText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section(strings.text(.behaviorSectionTitle)) {
                TimeValueControl(
                    title: strings.text(.bubbleDurationLabel),
                    binding: bubbleDurationSeconds,
                    range: 1...60,
                    unit: strings.text(.secondsSuffix)
                )

                Toggle(strings.text(.enableAutomaticActions), isOn: automaticActionsEnabled)

                TimeValueControl(
                    title: strings.text(.automaticActionFrequency),
                    binding: automaticActionIntervalMinutes,
                    range: 1...120,
                    unit: strings.text(.minuteSuffix)
                )

                Toggle(strings.text(.enableAutomaticRunning), isOn: automaticRunningEnabled)

                Picker(strings.text(.automaticRunDirection), selection: automaticRunDirectionMode) {
                    Text(strings.text(.automaticRunDirectionLeft)).tag(AutomaticRunDirectionMode.left)
                    Text(strings.text(.automaticRunDirectionRight)).tag(AutomaticRunDirectionMode.right)
                    Text(strings.text(.automaticRunDirectionRandom)).tag(AutomaticRunDirectionMode.random)
                }
                .pickerStyle(.segmented)
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

    private var restRemindersEnabled: Binding<Bool> {
        Binding(
            get: { settings.preferences.restRemindersEnabled },
            set: { value in
                if let onRestRemindersEnabledChanged {
                    onRestRemindersEnabledChanged(value)
                } else {
                    settings.updateRestRemindersEnabled(value)
                }
            }
        )
    }

    private var restBlockingEnabled: Binding<Bool> {
        Binding(
            get: { settings.preferences.restBlockingEnabled },
            set: { value in
                if let onRestBlockingEnabledChanged {
                    onRestBlockingEnabledChanged(value)
                } else {
                    settings.updateRestBlockingEnabled(value)
                }
            }
        )
    }

    private var restBlockingDurationSeconds: Binding<Int> {
        Binding(
            get: { settings.preferences.restBlockingDurationSeconds },
            set: { value in
                if let onRestBlockingDurationChanged {
                    onRestBlockingDurationChanged(value)
                } else {
                    settings.updateRestBlockingDuration(seconds: value)
                }
            }
        )
    }

    private var restBlockingScalePercent: Binding<Int> {
        Binding(
            get: { settings.preferences.restBlockingScalePercent },
            set: { value in
                if let onRestBlockingScaleChanged {
                    onRestBlockingScaleChanged(value)
                } else {
                    settings.updateRestBlockingScale(percent: value)
                }
            }
        )
    }

    private var waterRemindersEnabled: Binding<Bool> {
        Binding(
            get: { settings.preferences.waterRemindersEnabled },
            set: { value in
                if let onWaterRemindersEnabledChanged {
                    onWaterRemindersEnabledChanged(value)
                } else {
                    settings.updateWaterRemindersEnabled(value)
                }
            }
        )
    }

    private var waterIntervalMinutes: Binding<Int> {
        Binding(
            get: { settings.preferences.waterIntervalMinutes },
            set: { value in
                if let onWaterIntervalChanged {
                    onWaterIntervalChanged(value)
                } else {
                    settings.updateWaterInterval(minutes: value)
                }
            }
        )
    }

    private var bubbleDurationSeconds: Binding<Int> {
        Binding(
            get: { settings.preferences.bubbleDurationSeconds },
            set: { value in
                if let onBubbleDurationChanged {
                    onBubbleDurationChanged(value)
                } else {
                    settings.updateBubbleDuration(seconds: value)
                }
            }
        )
    }

    private var automaticActionsEnabled: Binding<Bool> {
        Binding(
            get: { settings.preferences.automaticActionsEnabled },
            set: { value in
                if let onAutomaticActionsEnabledChanged {
                    onAutomaticActionsEnabledChanged(value)
                } else {
                    settings.updateAutomaticActionsEnabled(value)
                }
            }
        )
    }

    private var automaticActionIntervalMinutes: Binding<Int> {
        Binding(
            get: { settings.preferences.automaticActionIntervalMinutes },
            set: { value in
                if let onAutomaticActionIntervalChanged {
                    onAutomaticActionIntervalChanged(value)
                } else {
                    settings.updateAutomaticActionInterval(minutes: value)
                }
            }
        )
    }

    private var automaticRunningEnabled: Binding<Bool> {
        Binding(
            get: { settings.preferences.automaticRunningEnabled },
            set: { value in
                if let onAutomaticRunningEnabledChanged {
                    onAutomaticRunningEnabledChanged(value)
                } else {
                    settings.updateAutomaticRunningEnabled(value)
                }
            }
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

    private var notificationStatusText: String {
        switch notificationPermissionStatus {
        case .off:
            return strings.text(.notificationOff)
        case .requesting:
            return strings.text(.notificationRequesting)
        case .enabled:
            return strings.text(.notificationEnabled)
        case .denied:
            return strings.text(.notificationDenied)
        case .failed:
            return strings.text(.notificationFailed)
        }
    }

    private func languageName(_ language: AppLanguage) -> String {
        switch language {
        case .system:
            return strings.text(.systemLanguageOption)
        case .chinese:
            return "中文"
        case .english:
            return "English"
        }
    }

    private var automaticRunDirectionMode: Binding<AutomaticRunDirectionMode> {
        Binding(
            get: { settings.preferences.automaticRunDirectionMode },
            set: { value in
                if let onAutomaticRunDirectionModeChanged {
                    onAutomaticRunDirectionModeChanged(value)
                } else {
                    settings.updateAutomaticRunDirectionMode(value)
                }
            }
        )
    }
}

private struct TimeValueControl: View {
    let title: String
    let range: ClosedRange<Int>
    let step: Int
    let unit: String

    @Binding private var value: Int

    init(title: String, binding: Binding<Int>, range: ClosedRange<Int>, step: Int = 1, unit: String) {
        self.title = title
        self._value = binding
        self.range = range
        self.step = step
        self.unit = unit
    }

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Stepper(value: $value, in: range, step: step) {
                EmptyView()
            }
            .labelsHidden()
            TextField("", value: $value, format: .number)
                .multilineTextAlignment(.trailing)
                .frame(width: 54)
            Text(unit)
                .foregroundStyle(.secondary)
                .frame(minWidth: 32, alignment: .leading)
        }
    }
}

import Foundation
import Observation
import SwiftUI
import MacPetCore

@MainActor
@Observable
final class AppRuntime {
    let settings: SettingsStore
    let stateMachine: PetStateMachine
    let scheduler: ReminderScheduler
    let restReminderScheduler: ReminderScheduler
    let waterReminderScheduler: IntervalScheduler
    let automaticActionScheduler: IntervalScheduler
    let petWindowController: PetWindowController
    private(set) var availablePets: [PetAsset]
    private(set) var selectedPetAsset: PetAsset

    @ObservationIgnored
    private let notificationClient: NotificationClientProtocol

    @ObservationIgnored
    private let petdexCatalog: PetdexCatalog

    @ObservationIgnored
    private var runtimeTask: Task<Void, Never>?

    @ObservationIgnored
    private var notificationAuthorizationRequested = false

    @ObservationIgnored
    private var terminationObserver: NSObjectProtocol?

    @ObservationIgnored
    private var blockingOverlayTask: Task<Void, Never>?

    @ObservationIgnored
    private var isRestBlockingOverlayActive = false

    init(
        settings: SettingsStore? = nil,
        stateMachine: PetStateMachine? = nil,
        scheduler: ReminderScheduler? = nil,
        petWindowController: PetWindowController? = nil,
        petdexCatalog: PetdexCatalog = PetdexCatalog(),
        notificationClient: NotificationClientProtocol = NotificationClient()
    ) {
        let settings = settings ?? SettingsStore()
        let availablePets = petdexCatalog.loadPets()
        let restReminderScheduler = scheduler ?? ReminderScheduler()

        self.settings = settings
        self.stateMachine = stateMachine ?? PetStateMachine()
        self.scheduler = restReminderScheduler
        self.restReminderScheduler = restReminderScheduler
        self.waterReminderScheduler = IntervalScheduler()
        self.automaticActionScheduler = IntervalScheduler()
        self.petWindowController = petWindowController ?? PetWindowController()
        self.availablePets = availablePets
        self.selectedPetAsset = Self.selectedPetAsset(
            from: availablePets,
            selectedPetID: settings.preferences.selectedPetID
        )
        self.notificationClient = notificationClient
        self.petdexCatalog = petdexCatalog

        self.petWindowController.onMoved = { [weak self] in
            self?.handlePetWindowMoved()
        }
    }

    deinit {
        runtimeTask?.cancel()
        if let terminationObserver {
            NotificationCenter.default.removeObserver(terminationObserver)
        }
    }

    func start() {
        guard runtimeTask == nil else {
            return
        }

        restReminderScheduler.onReminder = { [weak self] in
            self?.handleRestReminderDue()
        }

        if settings.preferences.restRemindersEnabled {
            restReminderScheduler.start(intervalMinutes: settings.preferences.reminderIntervalMinutes)
        }
        waterReminderScheduler.start(
            intervalMinutes: settings.preferences.waterIntervalMinutes,
            isEnabled: settings.preferences.waterRemindersEnabled
        ) { [weak self] in
            self?.handleWaterReminderDue()
        }
        automaticActionScheduler.start(
            intervalMinutes: automaticActionInterval(),
            isEnabled: settings.preferences.automaticActionsEnabled
        ) { [weak self] in
            self?.handleAutomaticActionDue()
        }
        requestNotificationAuthorizationIfNeeded()

        if settings.preferences.showPetOnLaunch {
            showPet()
        }

        if terminationObserver == nil {
            terminationObserver = NotificationCenter.default.addObserver(
                forName: .macPetWillTerminate,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.stop()
                }
            }
        }

        runtimeTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }

                handleDueReminders()
                stateMachine.tick(preferences: settings.preferences)
                completeTransientAnimationIfNeeded()

                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }

    func stop() {
        runtimeTask?.cancel()
        runtimeTask = nil
        blockingOverlayTask?.cancel()
        blockingOverlayTask = nil
        petWindowController.close()
    }

    func showPet() {
        let rootView = PetView(
            settings: settings,
            stateMachine: stateMachine,
            onDismissReminder: { [weak self] in
                self?.dismissActiveReminder()
            },
            strings: localizedStrings,
            petAsset: selectedPetAsset
        )
        petWindowController.show(rootView: rootView, scale: settings.preferences.petScale)
    }

    func hidePet() {
        petWindowController.hide()
    }

    func updatePetScale(_ scale: Double) {
        settings.updatePetScale(scale)
        petWindowController.updateScale(settings.preferences.petScale)
    }

    func updateReminderInterval(minutes: Int) {
        settings.updateReminderInterval(minutes: minutes)
        if settings.preferences.restRemindersEnabled {
            restReminderScheduler.updateInterval(minutes: settings.preferences.reminderIntervalMinutes)
        }
    }

    func updateSystemNotificationsEnabled(_ isEnabled: Bool) {
        settings.updateSystemNotificationsEnabled(isEnabled)
        requestNotificationAuthorizationIfNeeded()
    }

    func refreshPetCatalog() {
        let previousSelectedPetID = selectedPetAsset.id
        availablePets = petdexCatalog.loadPets()
        selectedPetAsset = Self.selectedPetAsset(
            from: availablePets,
            selectedPetID: settings.preferences.selectedPetID
        )
        if selectedPetAsset.id != settings.preferences.selectedPetID {
            settings.updateSelectedPetID(PetAsset.builtinID)
        }
        if selectedPetAsset.id != previousSelectedPetID {
            refreshPetWindowIfNeeded()
        }
    }

    func updateSelectedPet(_ petID: String) {
        settings.updateSelectedPetID(petID)
        selectedPetAsset = Self.selectedPetAsset(from: availablePets, selectedPetID: petID)
        refreshPetWindowIfNeeded()
    }

    func updateLanguage(_ language: AppLanguage) {
        settings.updateLanguage(language)
        refreshPetWindowIfNeeded()
    }

    func resetPetPosition() {
        petWindowController.resetPosition(scale: settings.preferences.petScale)
    }

    var localizedStrings: LocalizedStrings {
        LocalizedStrings(language: settings.preferences.language)
    }

    private func requestNotificationAuthorizationIfNeeded() {
        guard settings.preferences.systemNotificationsEnabled, !notificationAuthorizationRequested else {
            return
        }

        notificationAuthorizationRequested = true
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                _ = try await notificationClient.requestAuthorization()
            } catch {
                notificationAuthorizationRequested = false
                settings.updateSystemNotificationsEnabled(false)
            }
        }
    }

    private func completeTransientAnimationIfNeeded() {
        if stateMachine.state == .waking || stateMachine.state == .petting {
            stateMachine.handle(.animationCompleted)
        }
    }

    private func handleDueReminders() {
        restReminderScheduler.tick()
        if restReminderScheduler.isActive {
            return
        }
        waterReminderScheduler.tick()
        guard shouldTickAutomaticActionScheduler else {
            return
        }
        automaticActionScheduler.tick()
    }

    private func handleRestReminderDue() {
        stateMachine.handle(.reminderFired(.rest))
        showRestBlockingOverlay()
        if settings.preferences.systemNotificationsEnabled {
            notificationClient.sendRestReminder()
        }
    }

    private func handleWaterReminderDue() {
        stateMachine.handle(.reminderFired(.water))
    }

    private func handleAutomaticActionDue() {
        guard shouldTickAutomaticActionScheduler else {
            return
        }

        let action: AutomaticPetAction
        if settings.preferences.automaticRunningEnabled && !settings.preferences.lowerDistractionMode {
            action = .running
        } else {
            action = .blink
        }
        stateMachine.handle(.automaticAction(action))
        automaticActionScheduler.dismissActive()
    }

    private var shouldTickAutomaticActionScheduler: Bool {
        stateMachine.state == .idle
            && stateMachine.activeReminderKind == nil
            && !isRestBlockingOverlayActive
    }

    private func automaticActionInterval() -> Int {
        settings.preferences.automaticActionIntervalMinutes
    }

    private func showRestBlockingOverlay() {
        guard settings.preferences.restBlockingEnabled else {
            return
        }

        petWindowController.presentBlockingOverlay(scalePercent: settings.preferences.restBlockingScalePercent)
        isRestBlockingOverlayActive = true
        blockingOverlayTask?.cancel()
        blockingOverlayTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            try? await Task.sleep(
                nanoseconds: UInt64(settings.preferences.restBlockingDurationSeconds) * 1_000_000_000
            )
            hideRestBlockingOverlay()
        }
    }

    private func hideRestBlockingOverlay() {
        blockingOverlayTask?.cancel()
        blockingOverlayTask = nil
        petWindowController.restoreFromBlockingOverlay(scale: settings.preferences.petScale)
        isRestBlockingOverlayActive = false
    }

    private func dismissActiveReminder() {
        switch stateMachine.activeReminderKind {
        case .rest:
            scheduler.dismissActiveReminder()
            hideRestBlockingOverlay()
        case .water:
            waterReminderScheduler.dismissActive()
        case nil:
            return
        }

        stateMachine.handle(.dismissedReminder)
    }

    private func handlePetWindowMoved() {
        if stateMachine.state == .reminding {
            dismissActiveReminder()
        } else {
            stateMachine.handle(.dragged)
        }
    }

    private func refreshPetWindowIfNeeded() {
        guard petWindowController.window?.isVisible == true else {
            return
        }

        petWindowController.close()
        showPet()
    }

    private static func selectedPetAsset(from pets: [PetAsset], selectedPetID: String) -> PetAsset {
        pets.first { $0.id == selectedPetID } ?? PetAsset.builtin
    }
}

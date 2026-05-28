import AppKit
import Foundation
import Observation
import SwiftUI
import SlackerBuddyCore

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
    let displayState: PetDisplayState
    private(set) var availablePets: [PetAsset]
    private(set) var selectedPetAsset: PetAsset
    private(set) var notificationPermissionStatus: NotificationPermissionStatus

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
    private var automaticRunTask: Task<Void, Never>?

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
        self.displayState = PetDisplayState()
        self.availablePets = availablePets
        self.selectedPetAsset = Self.selectedPetAsset(
            from: availablePets,
            selectedPetID: settings.preferences.selectedPetID
        )
        self.notificationPermissionStatus = settings.preferences.systemNotificationsEnabled ? .requesting : .off
        self.notificationClient = notificationClient
        self.petdexCatalog = petdexCatalog

        self.petWindowController.onMoved = { [weak self] in
            self?.handlePetWindowMoved(direction: $0)
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
                stateMachine.tick()
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
        automaticRunTask?.cancel()
        automaticRunTask = nil
        petWindowController.close()
    }

    func showPet() {
        let rootView = PetView(
            settings: settings,
            stateMachine: stateMachine,
            displayState: displayState,
            onDismissReminder: { [weak self] in
                self?.dismissActiveReminder()
            },
            onPetTap: { [weak self] in
                self?.handlePetTap()
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

    func updateRestRemindersEnabled(_ isEnabled: Bool) {
        settings.updateRestRemindersEnabled(isEnabled)
        if isEnabled {
            restReminderScheduler.start(intervalMinutes: settings.preferences.reminderIntervalMinutes)
        } else {
            restReminderScheduler.stop()
            if stateMachine.activeReminderKind == .rest {
                dismissActiveReminder()
            }
        }
    }

    func updateRestBlockingEnabled(_ isEnabled: Bool) {
        settings.updateRestBlockingEnabled(isEnabled)
        if !isEnabled, isRestBlockingOverlayActive {
            hideRestBlockingOverlay()
        }
    }

    func updateRestBlockingDuration(seconds: Int) {
        settings.updateRestBlockingDuration(seconds: seconds)
    }

    func updateRestBlockingScale(percent: Int) {
        settings.updateRestBlockingScale(percent: percent)
        if isRestBlockingOverlayActive {
            displayState.petScaleOverride = petWindowController.presentBlockingOverlay(
                scalePercent: settings.preferences.restBlockingScalePercent
            )
        }
    }

    func updateWaterRemindersEnabled(_ isEnabled: Bool) {
        settings.updateWaterRemindersEnabled(isEnabled)
        waterReminderScheduler.update(
            intervalMinutes: settings.preferences.waterIntervalMinutes,
            isEnabled: settings.preferences.waterRemindersEnabled
        )
        if !isEnabled, stateMachine.activeReminderKind == .water {
            dismissActiveReminder()
        }
    }

    func updateWaterInterval(minutes: Int) {
        settings.updateWaterInterval(minutes: minutes)
        waterReminderScheduler.update(
            intervalMinutes: settings.preferences.waterIntervalMinutes,
            isEnabled: settings.preferences.waterRemindersEnabled
        )
    }

    func updateBubbleDuration(seconds: Int) {
        settings.updateBubbleDuration(seconds: seconds)
    }

    func updateAutomaticActionsEnabled(_ isEnabled: Bool) {
        settings.updateAutomaticActionsEnabled(isEnabled)
        automaticActionScheduler.update(
            intervalMinutes: automaticActionInterval(),
            isEnabled: settings.preferences.automaticActionsEnabled
        )
        if isEnabled {
            triggerAutomaticActionFeedback()
        }
    }

    func updateAutomaticActionInterval(minutes: Int) {
        settings.updateAutomaticActionInterval(minutes: minutes)
        automaticActionScheduler.update(
            intervalMinutes: automaticActionInterval(),
            isEnabled: settings.preferences.automaticActionsEnabled
        )
    }

    func updateAutomaticRunningEnabled(_ isEnabled: Bool) {
        settings.updateAutomaticRunningEnabled(isEnabled)
        if isEnabled, settings.preferences.automaticActionsEnabled {
            triggerAutomaticActionFeedback(preferRunning: true)
        }
    }

    func updateAutomaticRunDirectionMode(_ mode: AutomaticRunDirectionMode) {
        settings.updateAutomaticRunDirectionMode(mode)
        if settings.preferences.automaticRunningEnabled, settings.preferences.automaticActionsEnabled {
            triggerAutomaticActionFeedback(preferRunning: true)
        }
    }

    func updateSystemNotificationsEnabled(_ isEnabled: Bool) {
        settings.updateSystemNotificationsEnabled(isEnabled)
        if isEnabled {
            requestNotificationAuthorizationIfNeeded(force: true)
        } else {
            notificationPermissionStatus = .off
        }
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

    func focusSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 100_000_000)
            self?.bringSettingsWindowToFront()
        }
    }

    var localizedStrings: LocalizedStrings {
        LocalizedStrings(language: settings.preferences.language)
    }

    private func requestNotificationAuthorizationIfNeeded(force: Bool = false) {
        guard settings.preferences.systemNotificationsEnabled else {
            notificationPermissionStatus = .off
            return
        }
        guard force || !notificationAuthorizationRequested else {
            return
        }

        notificationAuthorizationRequested = true
        notificationPermissionStatus = .requesting
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                switch try await notificationClient.requestAuthorization() {
                case true:
                    notificationPermissionStatus = .enabled
                case false:
                    notificationPermissionStatus = .denied
                    notificationAuthorizationRequested = false
                    settings.updateSystemNotificationsEnabled(false)
                }
            } catch {
                notificationAuthorizationRequested = false
                notificationPermissionStatus = .failed
                settings.updateSystemNotificationsEnabled(false)
            }
        }
    }

    private func completeTransientAnimationIfNeeded() {
        if stateMachine.state == .waking ||
            stateMachine.state == .petting ||
            stateMachine.state == .waving ||
            stateMachine.state == .reviewing ||
            stateMachine.state == .jumping ||
            stateMachine.state == .failed ||
            stateMachine.state == .waiting ||
            stateMachine.state == .running ||
            stateMachine.state == .dragRunningLeft ||
            stateMachine.state == .dragRunningRight ||
            stateMachine.state == .automaticBlink ||
            stateMachine.state == .automaticRunningLeft ||
            stateMachine.state == .automaticRunningRight {
            stateMachine.handle(.animationCompleted)
        }
    }

    private func handleDueReminders() {
        tickReminderSchedulers()
        guard shouldTickAutomaticActionScheduler else {
            return
        }
        automaticActionScheduler.tick()
    }

    private func tickReminderSchedulers() {
        guard stateMachine.activeReminderKind == nil else {
            return
        }

        if settings.preferences.restRemindersEnabled {
            restReminderScheduler.tick()
            if restReminderScheduler.isActive {
                return
            }
        }
        waterReminderScheduler.tick()
    }

    private func handleRestReminderDue() {
        automaticRunTask?.cancel()
        automaticRunTask = nil
        stateMachine.handle(.reminderFired(.rest))
        showRestBlockingOverlay()
        if settings.preferences.systemNotificationsEnabled {
            notificationClient.sendRestReminder()
        }
    }

    private func handleWaterReminderDue() {
        automaticRunTask?.cancel()
        automaticRunTask = nil
        stateMachine.handle(.reminderFired(.water))
    }

    private func handleAutomaticActionDue() {
        guard shouldTickAutomaticActionScheduler else {
            return
        }

        let expressiveAction = randomExpressiveAction()
        if expressiveAction == .run,
           settings.preferences.automaticRunningEnabled,
           !settings.preferences.lowerDistractionMode {
            let direction = nextAutomaticRunDirectionValue()
            stateMachine.handle(.automaticAction(.running(direction)))
            performAutomaticRun(direction: direction)
        } else {
            stateMachine.handle(.automaticAction(.expressive(expressiveAction)))
        }
        automaticActionScheduler.dismissActive()
    }

    private func triggerAutomaticActionFeedback(preferRunning: Bool = false) {
        guard shouldTickAutomaticActionScheduler else {
            return
        }

        if preferRunning, settings.preferences.automaticRunningEnabled, !settings.preferences.lowerDistractionMode {
            let direction = nextAutomaticRunDirectionValue()
            stateMachine.handle(.automaticAction(.running(direction)))
            performAutomaticRun(direction: direction)
        } else if settings.preferences.automaticActionsEnabled {
            stateMachine.handle(.automaticAction(.expressive(randomExpressiveAction())))
        } else {
            stateMachine.handle(.automaticAction(.blink))
        }
    }

    private func performAutomaticRun(direction: PetMovementDirection) {
        automaticRunTask?.cancel()
        automaticRunTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            let step = direction == .left ? -14.0 : 14.0
            for _ in 0..<6 {
                guard !Task.isCancelled else {
                    return
                }

                petWindowController.moveHorizontally(points: step)
                try? await Task.sleep(nanoseconds: 120_000_000)
            }
        }
    }

    private func nextAutomaticRunDirectionValue() -> PetMovementDirection {
        switch settings.preferences.automaticRunDirectionMode {
        case .left:
            return .left
        case .right:
            return .right
        case .random:
            return Bool.random() ? .left : .right
        }
    }

    private func randomExpressiveAction() -> ExpressivePetAction {
        ExpressivePetAction.allCases.randomElement() ?? .wait
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

        let effectiveScale = petWindowController.presentBlockingOverlay(scalePercent: settings.preferences.restBlockingScalePercent)
        displayState.petScaleOverride = effectiveScale
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
        displayState.petScaleOverride = nil
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

    private func handlePetWindowMoved(direction: PetMovementDirection) {
        if stateMachine.state == .reminding {
            dismissActiveReminder()
        } else {
            stateMachine.handle(.dragged(direction))
        }
    }

    private func handlePetTap() {
        if stateMachine.state == .sleeping {
            stateMachine.handle(.clicked)
        } else {
            stateMachine.handle(.expressiveAction(randomExpressiveAction()))
        }
    }

    private func bringSettingsWindowToFront() {
        let expectedTitle = localizedStrings.text(.settingsTitle)
        for window in NSApp.windows where window !== petWindowController.window {
            guard window.title == expectedTitle || String(describing: type(of: window)).contains("Settings") else {
                continue
            }

            let originalLevel = window.level
            let originalCollectionBehavior = window.collectionBehavior
            window.collectionBehavior.insert(.moveToActiveSpace)
            window.level = .floating
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            restoreSettingsWindowLevel(
                window,
                to: originalLevel,
                collectionBehavior: originalCollectionBehavior
            )
        }
    }

    private func restoreSettingsWindowLevel(
        _ window: NSWindow,
        to level: NSWindow.Level,
        collectionBehavior: NSWindow.CollectionBehavior
    ) {
        Task { @MainActor [weak window] in
            try? await Task.sleep(nanoseconds: 750_000_000)
            window?.level = level
            window?.collectionBehavior = collectionBehavior
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

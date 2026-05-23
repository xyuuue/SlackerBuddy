import Observation
import SwiftUI
import MacPetCore

public struct PetView: View {
    @Bindable private var settings: SettingsStore
    @Bindable private var stateMachine: PetStateMachine

    private let scheduler: ReminderScheduler
    private let animator = SpriteAnimator()

    @State private var animationStartedAt = Date()
    @State private var schedulerStarted = false

    public init(
        settings: SettingsStore,
        stateMachine: PetStateMachine,
        scheduler: ReminderScheduler
    ) {
        self.settings = settings
        self.stateMachine = stateMachine
        self.scheduler = scheduler
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.25)) { context in
            let elapsed = context.date.timeIntervalSince(animationStartedAt)
            let frame = animator.frame(
                for: stateMachine.state,
                elapsed: elapsed,
                lowerDistractionMode: settings.preferences.lowerDistractionMode
            )

            VStack(spacing: 8) {
                if let bubbleText = stateMachine.bubbleText,
                   !settings.preferences.lowerDistractionMode {
                    BubbleView(text: bubbleText, onDismiss: dismissReminder)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                PixelCatPlaceholderView(frameName: frame)
                    .frame(
                        width: 128 * settings.preferences.petScale,
                        height: 128 * settings.preferences.petScale
                    )
                    .contentShape(Rectangle())
                    .onTapGesture(perform: handlePetTap)
                    .accessibilityAddTraits(.isButton)
            }
            .padding(12)
            .fixedSize()
            .onChange(of: context.date) { _, date in
                tick(at: date)
            }
        }
        .onAppear(perform: startSchedulerIfNeeded)
        .onChange(of: settings.preferences.reminderIntervalMinutes) { _, minutes in
            scheduler.updateInterval(minutes: minutes)
        }
        .onChange(of: stateMachine.state) { _, _ in
            animationStartedAt = Date()
        }
    }

    private func startSchedulerIfNeeded() {
        scheduler.onReminder = {
            stateMachine.handle(.reminderFired)
        }

        guard !schedulerStarted else {
            return
        }

        scheduler.start(intervalMinutes: settings.preferences.reminderIntervalMinutes)
        schedulerStarted = true
    }

    private func tick(at date: Date) {
        scheduler.tick()
        stateMachine.tick(preferences: settings.preferences)

        let elapsed = date.timeIntervalSince(animationStartedAt)
        if elapsed >= 0.5, stateMachine.state == .waking || stateMachine.state == .petting {
            stateMachine.handle(.animationCompleted)
        }
    }

    private func handlePetTap() {
        if scheduler.isReminderActive || stateMachine.state == .reminding {
            dismissReminder()
        } else {
            stateMachine.handle(.clicked)
        }
    }

    private func dismissReminder() {
        scheduler.dismissActiveReminder()
        stateMachine.handle(.dismissedReminder)
    }
}

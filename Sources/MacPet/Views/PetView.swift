import Observation
import SwiftUI
import MacPetCore

public struct PetView: View {
    @Bindable private var settings: SettingsStore
    @Bindable private var stateMachine: PetStateMachine

    private let scheduler: ReminderScheduler
    private let animator = SpriteAnimator()

    @State private var animationStartedAt = Date()

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
        }
        .onChange(of: stateMachine.state) { _, _ in
            animationStartedAt = Date()
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

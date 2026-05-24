import Observation
import SwiftUI
import MacPetCore

public struct PetView: View {
    @Bindable private var settings: SettingsStore
    @Bindable private var stateMachine: PetStateMachine

    private let scheduler: ReminderScheduler
    private let strings: LocalizedStrings
    private let petAsset: PetAsset
    private let animator = SpriteAnimator()

    @State private var animationStartedAt = Date()

    public init(
        settings: SettingsStore,
        stateMachine: PetStateMachine,
        scheduler: ReminderScheduler,
        strings: LocalizedStrings,
        petAsset: PetAsset
    ) {
        self.settings = settings
        self.stateMachine = stateMachine
        self.scheduler = scheduler
        self.strings = strings
        self.petAsset = petAsset
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
                    BubbleView(text: localizedBubbleText(fallback: bubbleText), onDismiss: dismissReminder)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                petContent(frameName: frame)
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

    @ViewBuilder
    private func petContent(frameName: String) -> some View {
        if let spriteSheetURL = petAsset.spriteSheetURL {
            PetSpriteSheetView(
                spriteSheetURL: spriteSheetURL,
                state: stateMachine.state,
                frameName: frameName
            )
        } else {
            PixelCatPlaceholderView(frameName: frameName)
        }
    }

    private func localizedBubbleText(fallback: String) -> String {
        stateMachine.state == .reminding ? strings.text(.restReminderBubble) : fallback
    }
}

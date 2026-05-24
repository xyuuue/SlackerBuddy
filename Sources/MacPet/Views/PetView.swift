import Observation
import SwiftUI
import MacPetCore

public struct PetView: View {
    @Bindable private var settings: SettingsStore
    @Bindable private var stateMachine: PetStateMachine

    private let onDismissReminder: () -> Void
    private let strings: LocalizedStrings
    private let petAsset: PetAsset
    private let animator = SpriteAnimator()

    @State private var animationStartedAt = Date()
    @State private var isBubbleVisible = true
    @State private var bubbleHideTask: Task<Void, Never>?

    public init(
        settings: SettingsStore,
        stateMachine: PetStateMachine,
        onDismissReminder: @escaping () -> Void,
        strings: LocalizedStrings,
        petAsset: PetAsset
    ) {
        self.settings = settings
        self.stateMachine = stateMachine
        self.onDismissReminder = onDismissReminder
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
                   isBubbleVisible,
                   !settings.preferences.lowerDistractionMode {
                    BubbleView(text: localizedBubbleText(fallback: bubbleText), onDismiss: dismissReminder)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                petContent(frameName: frame)
                    .scaleEffect(x: shouldFaceLeft(frameName: frame) ? -1 : 1, y: 1)
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
        .onChange(of: stateMachine.bubbleText) { _, _ in
            scheduleBubbleAutoHide()
        }
        .onChange(of: stateMachine.activeReminderKind) { _, _ in
            scheduleBubbleAutoHide()
        }
        .onAppear {
            scheduleBubbleAutoHide()
        }
    }

    private func handlePetTap() {
        if stateMachine.state == .reminding {
            dismissReminder()
        } else {
            stateMachine.handle(.clicked)
        }
    }

    private func dismissReminder() {
        onDismissReminder()
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
        guard stateMachine.state == .reminding else {
            return fallback
        }

        switch stateMachine.activeReminderKind {
        case .rest:
            return strings.text(.restReminderBubble)
        case .water:
            return strings.text(.waterReminderBubble)
        case nil:
            return fallback
        }
    }

    private func shouldFaceLeft(frameName: String) -> Bool {
        frameName.contains("left")
    }

    private func scheduleBubbleAutoHide() {
        bubbleHideTask?.cancel()

        guard stateMachine.bubbleText != nil else {
            isBubbleVisible = true
            return
        }

        isBubbleVisible = true
        let durationSeconds = settings.preferences.bubbleDurationSeconds
        bubbleHideTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(durationSeconds) * 1_000_000_000)
            guard !Task.isCancelled else {
                return
            }

            isBubbleVisible = false
        }
    }
}

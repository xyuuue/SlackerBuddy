# Reminders And Autonomy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add configurable rest and water reminders, adjustable bubble timing, autonomous pet actions, and optional rest blocking overlay to Mac Pet.

**Architecture:** `MacPetCore` owns preference persistence, scheduler behavior, reminder kind modeling, and pet state transitions. The macOS app layer owns AppKit-only blocking presentation and wires settings controls to runtime schedulers. Tests start with pure core behavior, then add source-level checks for UI/window integration.

**Tech Stack:** SwiftPM, Swift 5.9, SwiftUI, AppKit, existing executable `MacPetTestRunner`, `DEVELOPER_DIR=/Library/Developer/CommandLineTools`.

---

## File Structure

- Modify `Sources/MacPetCore/Models/PetPreferences.swift`: add new reminder, bubble, automatic action, and blocking settings with clamps.
- Modify `Sources/MacPetCore/Stores/SettingsStore.swift`: load, persist, and update each new setting.
- Modify `Sources/MacPetCore/Localization/LocalizedStrings.swift`: add labels and reminder bubble copy in Chinese and English.
- Create `Sources/MacPetCore/Models/ReminderKind.swift`: distinguish rest and water reminders.
- Create `Sources/MacPetCore/Services/IntervalScheduler.swift`: reusable enable-aware scheduler for rest, water, and automatic actions.
- Keep `Sources/MacPetCore/Services/ReminderScheduler.swift` only if existing tests still need it; otherwise adapt tests to `IntervalScheduler` and leave `ReminderScheduler` as a compatibility wrapper.
- Modify `Sources/MacPetCore/Models/PetState.swift`: add automatic action and running states if needed by animation mapping.
- Modify `Sources/MacPetCore/State/PetStateMachine.swift`: support rest/water reminder copy and automatic action events.
- Modify `Sources/MacPetCore/Animation/SpriteAnimator.swift`: map automatic blink/running state to existing atlas rows/frame names.
- Modify `Sources/MacPet/App/AppRuntime.swift`: own rest, water, and automatic-action schedulers; trigger blocking overlay.
- Modify `Sources/MacPet/Windowing/PetWindowController.swift`: add temporary blocking presentation that restores normal frame/scale without persisting placement.
- Modify `Sources/MacPet/Views/PetView.swift`: auto-hide bubbles after configured seconds without dismissing active reminders.
- Modify `Sources/MacPet/Views/SettingsView.swift`: add controls matching the screenshot.
- Modify tests under `Tests/MacPetTestRunner/*`.

## Task 1: Preferences And Localized Copy

**Files:**
- Modify: `Sources/MacPetCore/Models/PetPreferences.swift`
- Modify: `Sources/MacPetCore/Stores/SettingsStore.swift`
- Modify: `Sources/MacPetCore/Localization/LocalizedStrings.swift`
- Modify: `Tests/MacPetTestRunner/SettingsStoreTests.swift`
- Modify: `Tests/MacPetTestRunner/LocalizationTests.swift`

- [ ] **Step 1: Write failing tests for defaults, clamping, persistence, and strings**

Add these expectations to `SettingsStoreTests.swift`:

```swift
try expect(store.preferences.restRemindersEnabled == true, "Expected rest reminders enabled by default")
try expect(store.preferences.reminderIntervalMinutes == 45, "Expected rest interval to default to 45")
try expect(store.preferences.restBlockingEnabled == true, "Expected rest blocking enabled by default")
try expect(store.preferences.restBlockingDurationSeconds == 15, "Expected blocking duration to default to 15 seconds")
try expect(store.preferences.restBlockingScalePercent == 40, "Expected blocking scale to default to 40 percent")
try expect(store.preferences.waterRemindersEnabled == true, "Expected water reminders enabled by default")
try expect(store.preferences.waterIntervalMinutes == 90, "Expected water interval to default to 90")
try expect(store.preferences.bubbleDurationSeconds == 6, "Expected bubble duration to default to 6 seconds")
try expect(store.preferences.automaticActionsEnabled == true, "Expected automatic actions enabled by default")
try expect(store.preferences.automaticActionIntervalMinutes == 8, "Expected automatic action interval to default to 8")
try expect(store.preferences.automaticRunningEnabled == false, "Expected automatic running off by default")
```

Add a persistence test that updates every new field:

```swift
store.updateRestRemindersEnabled(false)
store.updateRestBlockingEnabled(false)
store.updateRestBlockingDuration(seconds: 30)
store.updateRestBlockingScale(percent: 55)
store.updateWaterRemindersEnabled(false)
store.updateWaterInterval(minutes: 120)
store.updateBubbleDuration(seconds: 9)
store.updateAutomaticActionsEnabled(false)
store.updateAutomaticActionInterval(minutes: 12)
store.updateAutomaticRunningEnabled(true)

let reloadedStore = SettingsStore(defaults: defaults)
try expect(reloadedStore.preferences.restRemindersEnabled == false, "Expected rest reminder toggle to persist")
try expect(reloadedStore.preferences.restBlockingDurationSeconds == 30, "Expected blocking duration to persist")
try expect(reloadedStore.preferences.restBlockingScalePercent == 55, "Expected blocking scale to persist")
try expect(reloadedStore.preferences.waterRemindersEnabled == false, "Expected water reminder toggle to persist")
try expect(reloadedStore.preferences.waterIntervalMinutes == 120, "Expected water interval to persist")
try expect(reloadedStore.preferences.bubbleDurationSeconds == 9, "Expected bubble duration to persist")
try expect(reloadedStore.preferences.automaticActionsEnabled == false, "Expected automatic action toggle to persist")
try expect(reloadedStore.preferences.automaticActionIntervalMinutes == 12, "Expected automatic action interval to persist")
try expect(reloadedStore.preferences.automaticRunningEnabled == true, "Expected automatic running toggle to persist")
```

Add clamp expectations:

```swift
let preferences = PetPreferences(
    reminderIntervalMinutes: 0,
    restBlockingDurationSeconds: 0,
    restBlockingScalePercent: 5,
    waterIntervalMinutes: 0,
    bubbleDurationSeconds: 0,
    automaticActionIntervalMinutes: 0
)
try expect(preferences.reminderIntervalMinutes == 1, "Expected rest interval to clamp to 1")
try expect(preferences.restBlockingDurationSeconds == 1, "Expected blocking duration to clamp to 1")
try expect(preferences.restBlockingScalePercent == 10, "Expected blocking scale to clamp to 10")
try expect(preferences.waterIntervalMinutes == 1, "Expected water interval to clamp to 1")
try expect(preferences.bubbleDurationSeconds == 1, "Expected bubble duration to clamp to 1")
try expect(preferences.automaticActionIntervalMinutes == 1, "Expected automatic action interval to clamp to 1")
```

Add localization expectations to `LocalizationTests.swift`:

```swift
let zh = LocalizedStrings(language: .chinese)
let en = LocalizedStrings(language: .english)
try expect(zh.text(.enableRestReminders) == "开启休息提醒", "Expected Chinese rest toggle")
try expect(en.text(.enableRestReminders) == "Enable rest reminders", "Expected English rest toggle")
try expect(zh.text(.waterReminderBubble) == "喝点水吧", "Expected Chinese water copy")
try expect(en.text(.waterReminderBubble) == "Time to drink water", "Expected English water copy")
try expect(zh.text(.secondsSuffix) == "秒", "Expected Chinese seconds suffix")
try expect(en.text(.percentSuffix) == "%", "Expected English percent suffix")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: compile failures for missing preference fields, settings update methods, and localized keys.

- [ ] **Step 3: Implement preferences, persistence, and strings**

Add fields to `PetPreferences`:

```swift
public var restRemindersEnabled: Bool
public var restBlockingEnabled: Bool
public var restBlockingDurationSeconds: Int
public var restBlockingScalePercent: Int
public var waterRemindersEnabled: Bool
public var waterIntervalMinutes: Int
public var bubbleDurationSeconds: Int
public var automaticActionsEnabled: Bool
public var automaticActionIntervalMinutes: Int
public var automaticRunningEnabled: Bool
```

Use these clamps:

```swift
self.restBlockingDurationSeconds = min(max(restBlockingDurationSeconds, 1), 300)
self.restBlockingScalePercent = min(max(restBlockingScalePercent, 10), 90)
self.waterIntervalMinutes = min(max(waterIntervalMinutes, 1), 480)
self.bubbleDurationSeconds = min(max(bubbleDurationSeconds, 1), 60)
self.automaticActionIntervalMinutes = min(max(automaticActionIntervalMinutes, 1), 120)
```

Update `SettingsStore` with keys and update methods:

```swift
public func updateRestRemindersEnabled(_ isEnabled: Bool)
public func updateRestBlockingEnabled(_ isEnabled: Bool)
public func updateRestBlockingDuration(seconds: Int)
public func updateRestBlockingScale(percent: Int)
public func updateWaterRemindersEnabled(_ isEnabled: Bool)
public func updateWaterInterval(minutes: Int)
public func updateBubbleDuration(seconds: Int)
public func updateAutomaticActionsEnabled(_ isEnabled: Bool)
public func updateAutomaticActionInterval(minutes: Int)
public func updateAutomaticRunningEnabled(_ isEnabled: Bool)
```

Add localized keys:

```swift
case bubbleDurationLabel
case enableAutomaticActions
case automaticActionFrequency
case enableAutomaticRunning
case enableRestReminders
case restBlockingEnabled
case restBlockingDuration
case restBlockingScale
case enableWaterReminders
case waterIntervalLabel
case waterReminderBubble
case secondsSuffix
case percentSuffix
case behaviorSectionTitle
```

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all tests pass.

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources/MacPetCore Tests/MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: add reminder and autonomy preferences"
```

## Task 2: Reusable Schedulers And Reminder Priority

**Files:**
- Create: `Sources/MacPetCore/Models/ReminderKind.swift`
- Create: `Sources/MacPetCore/Services/IntervalScheduler.swift`
- Modify: `Sources/MacPetCore/Services/ReminderScheduler.swift`
- Modify: `Tests/MacPetTestRunner/ReminderSchedulerTests.swift`
- Create: `Tests/MacPetTestRunner/IntervalSchedulerTests.swift`
- Modify: `Tests/MacPetTestRunner/main.swift`

- [ ] **Step 1: Write failing scheduler tests**

Create `IntervalSchedulerTests.swift`:

```swift
import Foundation
import MacPetCore

let intervalSchedulerTests: [TestCase] = [
    TestCase(name: "disabled scheduler does not fire") {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = IntervalScheduler(now: { current })
        var fired = false
        scheduler.start(intervalMinutes: 1, isEnabled: false) { fired = true }
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()
        try expect(!fired, "Expected disabled scheduler not to fire")
    },
    TestCase(name: "enabled scheduler fires once and stays active") {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = IntervalScheduler(now: { current })
        var fireCount = 0
        scheduler.start(intervalMinutes: 1, isEnabled: true) { fireCount += 1 }
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()
        scheduler.tick()
        try expect(fireCount == 1, "Expected active scheduler to fire once")
        try expect(scheduler.isActive == true, "Expected scheduler to remain active until dismissed")
    },
    TestCase(name: "dismiss schedules next interval") {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = IntervalScheduler(now: { current })
        var fireCount = 0
        scheduler.start(intervalMinutes: 1, isEnabled: true) { fireCount += 1 }
        current = Date(timeIntervalSince1970: 61)
        scheduler.tick()
        scheduler.dismissActive()
        current = Date(timeIntervalSince1970: 122)
        scheduler.tick()
        try expect(fireCount == 2, "Expected dismiss to schedule next reminder")
    }
]
```

Add a priority source-level test to `AppLifecycleSourceTests.swift`:

```swift
try expect(appRuntimeSource.contains("handleDueReminders()"), "Runtime should centralize rest and water priority")
try expect(appRuntimeSource.contains("restReminderScheduler.tick()"), "Runtime should tick rest scheduler")
try expect(appRuntimeSource.contains("waterReminderScheduler.tick()"), "Runtime should tick water scheduler")
try expect(appRuntimeSource.contains("if restReminderScheduler.isActive"), "Rest reminder should take priority")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: compile failure for missing `IntervalScheduler` and `ReminderKind`.

- [ ] **Step 3: Implement scheduler and reminder kind**

Create `ReminderKind.swift`:

```swift
public enum ReminderKind: Equatable, Sendable {
    case rest
    case water
}
```

Create `IntervalScheduler.swift`:

```swift
@MainActor
public final class IntervalScheduler {
    public private(set) var isActive = false
    private var isEnabled = false
    private var intervalMinutes = 1
    private var nextFireAt: Date?
    private var onFire: (() -> Void)?
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    public func start(intervalMinutes: Int, isEnabled: Bool, onFire: @escaping () -> Void) {
        self.intervalMinutes = max(1, intervalMinutes)
        self.isEnabled = isEnabled
        self.onFire = onFire
        isActive = false
        scheduleNext(from: now())
    }

    public func update(intervalMinutes: Int, isEnabled: Bool) {
        self.intervalMinutes = max(1, intervalMinutes)
        self.isEnabled = isEnabled
        isActive = false
        scheduleNext(from: now())
    }

    public func tick() {
        guard isEnabled, !isActive, let nextFireAt, now() >= nextFireAt else {
            return
        }
        isActive = true
        onFire?()
    }

    public func dismissActive() {
        isActive = false
        scheduleNext(from: now())
    }

    public func stop() {
        isEnabled = false
        isActive = false
        nextFireAt = nil
    }

    private func scheduleNext(from date: Date) {
        nextFireAt = isEnabled ? date.addingTimeInterval(TimeInterval(intervalMinutes * 60)) : nil
    }
}
```

Keep `ReminderScheduler` as a thin wrapper over `IntervalScheduler` so older tests can still pass.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all scheduler tests pass.

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources/MacPetCore Tests/MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: add reusable interval schedulers"
```

## Task 3: Pet State, Bubble Timing, And Automatic Actions

**Files:**
- Modify: `Sources/MacPetCore/Models/PetState.swift`
- Modify: `Sources/MacPetCore/State/PetStateMachine.swift`
- Modify: `Sources/MacPetCore/Animation/SpriteAnimator.swift`
- Modify: `Sources/MacPetCore/Petdex/SpriteFrameMapping.swift`
- Modify: `Sources/MacPet/Views/PetView.swift`
- Modify: `Tests/MacPetTestRunner/PetStateMachineTests.swift`
- Modify: `Tests/MacPetTestRunner/SpriteAnimatorTests.swift`
- Modify: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] **Step 1: Write failing state-machine and bubble tests**

Add tests:

```swift
TestCase(name: "state machine shows water reminder bubble") {
    let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })
    machine.handle(.reminderFired(.water))
    try expect(machine.state == .reminding, "Expected water reminder to use reminding state")
    try expect(machine.activeReminderKind == .water, "Expected active water reminder kind")
},
TestCase(name: "automatic action does not reset inactivity") {
    var current = Date(timeIntervalSince1970: 0)
    let machine = PetStateMachine(now: { current })
    current = Date(timeIntervalSince1970: 60)
    machine.handle(.automaticAction(.blink))
    current = Date(timeIntervalSince1970: 30 * 60)
    machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))
    try expect(machine.state == .sleeping, "Expected automatic action not to reset user inactivity")
},
TestCase(name: "automatic running is suppressed in lower distraction mode") {
    let animator = SpriteAnimator()
    let frame = animator.frame(for: .automaticRunning, elapsed: 0, lowerDistractionMode: true)
    try expect(frame.hasPrefix("idle"), "Expected lower distraction mode to suppress automatic running frames")
}
```

Add source-level bubble duration test:

```swift
try expect(petViewSource.contains("bubbleDurationSeconds"), "PetView should use configured bubble duration")
try expect(petViewSource.contains("Task.sleep"), "PetView should auto-hide bubbles after a delay")
try expect(petViewSource.contains("isBubbleVisible"), "PetView should hide bubble without dismissing reminder")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: compile failures for missing `ReminderKind`-aware events, `activeReminderKind`, automatic action states, and bubble visibility code.

- [ ] **Step 3: Implement state and animation**

Update `PetState`:

```swift
case automaticBlink
case automaticRunning
```

Update `PetEvent`:

```swift
case reminderFired(ReminderKind)
case automaticAction(AutomaticPetAction)
```

Create `AutomaticPetAction` in `PetState.swift`:

```swift
public enum AutomaticPetAction: Equatable, Sendable {
    case blink
    case running
}
```

Update `PetStateMachine`:

- Store `public private(set) var activeReminderKind: ReminderKind?`.
- `reminderFired(.rest)` sets state `.reminding`, active kind `.rest`, and bubble text key fallback `"休息一下吧"`.
- `reminderFired(.water)` sets state `.reminding`, active kind `.water`, and bubble text fallback `"喝点水吧"`.
- `dismissedReminder` clears `activeReminderKind`.
- `automaticAction(.blink)` sets `.automaticBlink` only from `.idle`.
- `automaticAction(.running)` sets `.automaticRunning` only from `.idle`.
- `animationCompleted` returns automatic states to `.idle`.

Update `SpriteAnimator`:

- `.automaticBlink` maps to blink frames.
- `.automaticRunning` maps to running frames unless lower-distraction mode is true, then idle frames.

Update `SpriteFrameMapping`:

- `.automaticBlink` maps to row 0 or row 8.
- `.automaticRunning` maps to row 7.

Update `PetView`:

- Add `@State private var isBubbleVisible = true`.
- On bubble text changes, set visible true and start a `Task.sleep` for `settings.preferences.bubbleDurationSeconds`.
- Hide the bubble by setting `isBubbleVisible = false`; do not call `dismissReminder()`.
- Localize bubble text by `stateMachine.activeReminderKind`.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all state, animation, and bubble tests pass.

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources Tests
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: add reminder kinds and automatic actions"
```

## Task 4: Runtime Wiring And Blocking Overlay

**Files:**
- Modify: `Sources/MacPet/App/AppRuntime.swift`
- Modify: `Sources/MacPet/Windowing/PetWindowController.swift`
- Modify: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] **Step 1: Write failing runtime source tests**

Add source-level tests:

```swift
try expect(appRuntimeSource.contains("restReminderScheduler"), "Runtime should own rest scheduler")
try expect(appRuntimeSource.contains("waterReminderScheduler"), "Runtime should own water scheduler")
try expect(appRuntimeSource.contains("automaticActionScheduler"), "Runtime should own automatic action scheduler")
try expect(appRuntimeSource.contains("showRestBlockingOverlay"), "Runtime should show rest blocking overlay")
try expect(appRuntimeSource.contains("hideRestBlockingOverlay"), "Runtime should hide rest blocking overlay")
try expect(windowSource.contains("presentBlockingOverlay"), "Window controller should present blocking overlay")
try expect(windowSource.contains("restoreFromBlockingOverlay"), "Window controller should restore after blocking overlay")
try expect(!windowSource.contains("saveCurrentFrame()") || windowSource.contains("isBlockingOverlayActive"), "Blocking overlay should not persist as normal placement")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: source-level tests fail because runtime/window overlay APIs do not exist.

- [ ] **Step 3: Implement runtime wiring**

In `AppRuntime`, replace single scheduler use with:

```swift
let restReminderScheduler: IntervalScheduler
let waterReminderScheduler: IntervalScheduler
let automaticActionScheduler: IntervalScheduler
```

Start schedulers:

```swift
restReminderScheduler.start(intervalMinutes: settings.preferences.reminderIntervalMinutes, isEnabled: settings.preferences.restRemindersEnabled) { [weak self] in
    self?.handleRestReminderDue()
}
waterReminderScheduler.start(intervalMinutes: settings.preferences.waterIntervalMinutes, isEnabled: settings.preferences.waterRemindersEnabled) { [weak self] in
    self?.handleWaterReminderDue()
}
automaticActionScheduler.start(intervalMinutes: automaticActionInterval(), isEnabled: settings.preferences.automaticActionsEnabled) { [weak self] in
    self?.handleAutomaticActionDue()
}
```

Implement:

```swift
private func handleDueReminders()
private func handleRestReminderDue()
private func handleWaterReminderDue()
private func handleAutomaticActionDue()
private func showRestBlockingOverlay()
private func hideRestBlockingOverlay()
private func dismissActiveReminder()
```

Rules:

- Rest takes priority over water.
- Water does not show blocking overlay.
- Automatic action does nothing while `stateMachine.state != .idle`.
- Lower-distraction mode suppresses automatic running.
- Updating intervals or toggles calls `IntervalScheduler.update`.
- Dismissing a reminder dismisses only the active reminder kind.

- [ ] **Step 4: Implement window overlay**

In `PetWindowController`, add:

```swift
private var preBlockingFrame: NSRect?
private var isBlockingOverlayActive = false

func presentBlockingOverlay(scalePercent: Int)
func restoreFromBlockingOverlay(scale: Double)
```

`presentBlockingOverlay` centers the existing pet window on `NSScreen.main?.visibleFrame`, sizes it to `min(width, height) * scalePercent / 100`, and does not write `frameDefaultsKey`.

`restoreFromBlockingOverlay` restores `preBlockingFrame` if available and clears `isBlockingOverlayActive`.

Guard normal frame persistence so blocking overlay moves do not save:

```swift
guard !isBlockingOverlayActive else { return }
```

- [ ] **Step 5: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build
```

Expected: all tests and build pass.

- [ ] **Step 6: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources Tests
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: wire rest water and blocking runtime"
```

## Task 5: Settings UI Controls

**Files:**
- Modify: `Sources/MacPet/Views/SettingsView.swift`
- Modify: `Sources/MacPet/App/AppRuntime.swift`
- Modify: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] **Step 1: Write failing settings source tests**

Add source-level checks:

```swift
try expect(settingsSource.contains("Toggle(strings.text(.enableRestReminders)"), "Settings should expose rest reminder toggle")
try expect(settingsSource.contains("Stepper(value: reminderIntervalMinutes"), "Settings should expose rest interval stepper")
try expect(settingsSource.contains("Toggle(strings.text(.restBlockingEnabled)"), "Settings should expose blocking toggle")
try expect(settingsSource.contains("Stepper(value: restBlockingDurationSeconds"), "Settings should expose blocking duration stepper")
try expect(settingsSource.contains("Stepper(value: restBlockingScalePercent"), "Settings should expose blocking scale stepper")
try expect(settingsSource.contains("Toggle(strings.text(.enableWaterReminders)"), "Settings should expose water toggle")
try expect(settingsSource.contains("Stepper(value: waterIntervalMinutes"), "Settings should expose water interval stepper")
try expect(settingsSource.contains("Stepper(value: bubbleDurationSeconds"), "Settings should expose bubble duration stepper")
try expect(settingsSource.contains("Toggle(strings.text(.enableAutomaticActions)"), "Settings should expose automatic actions toggle")
try expect(settingsSource.contains("Stepper(value: automaticActionIntervalMinutes"), "Settings should expose automatic frequency stepper")
try expect(settingsSource.contains("Toggle(strings.text(.enableAutomaticRunning)"), "Settings should expose automatic running toggle")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: source-level tests fail because controls do not exist.

- [ ] **Step 3: Implement controls and runtime callbacks**

Add callbacks to `SettingsView.init`:

```swift
onRestRemindersEnabledChanged: ((Bool) -> Void)?
onRestBlockingEnabledChanged: ((Bool) -> Void)?
onRestBlockingDurationChanged: ((Int) -> Void)?
onRestBlockingScaleChanged: ((Int) -> Void)?
onWaterRemindersEnabledChanged: ((Bool) -> Void)?
onWaterIntervalChanged: ((Int) -> Void)?
onBubbleDurationChanged: ((Int) -> Void)?
onAutomaticActionsEnabledChanged: ((Bool) -> Void)?
onAutomaticActionIntervalChanged: ((Int) -> Void)?
onAutomaticRunningEnabledChanged: ((Bool) -> Void)?
```

Add bindings for each setting. Use existing `Stepper` style and suffixes:

```swift
Text("\(strings.text(.restBlockingDuration)): \(settings.preferences.restBlockingDurationSeconds) \(strings.text(.secondsSuffix))")
Text("\(strings.text(.restBlockingScale)): \(settings.preferences.restBlockingScalePercent) \(strings.text(.percentSuffix))")
```

Add runtime methods:

```swift
func updateRestRemindersEnabled(_ isEnabled: Bool)
func updateRestBlockingEnabled(_ isEnabled: Bool)
func updateRestBlockingDuration(seconds: Int)
func updateRestBlockingScale(percent: Int)
func updateWaterRemindersEnabled(_ isEnabled: Bool)
func updateWaterInterval(minutes: Int)
func updateBubbleDuration(seconds: Int)
func updateAutomaticActionsEnabled(_ isEnabled: Bool)
func updateAutomaticActionInterval(minutes: Int)
func updateAutomaticRunningEnabled(_ isEnabled: Bool)
```

Pass these callbacks from `MacPetApp.Settings`.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all settings source tests pass.

- [ ] **Step 5: Commit**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources Tests
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: add reminder and action settings"
```

## Task 6: Final Verification

**Files:**
- No planned source changes except fixes from verification.

- [ ] **Step 1: Run full verification**

Run:

```bash
./script/build_and_run.sh --verify
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build -Xswiftc -warn-concurrency -Xswiftc -strict-concurrency=complete
DEVELOPER_DIR=/Library/Developer/CommandLineTools git diff --check
```

Expected: every command exits 0, tests report 0 failures, strict concurrency build has no new warnings.

- [ ] **Step 2: Manual launch smoke**

Run:

```bash
./script/build_and_run.sh
```

Confirm the app launches. Open Settings and verify:

- Rest reminders can be toggled off and on.
- Water reminders can be toggled off and on.
- Bubble duration, rest interval, blocking duration, blocking scale, water interval, and automatic action frequency controls display localized units.
- Automatic running toggle is present.
- Lower-distraction mode suppresses automatic running.
- Rest blocking overlay enlarges and restores the pet without saving that frame as normal placement.

- [ ] **Step 3: Commit final fixes if needed**

If verification requires fixes:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources Tests
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "fix: stabilize reminders and autonomy"
```

## Self-Review

- Spec coverage: bubble duration, automatic actions, automatic running, rest enable/disable, rest blocking overlay, water reminders, defaults, lower-distraction behavior, localization, persistence, and verification are all assigned to tasks.
- Completeness scan: no task contains unfilled markers or deferred decisions.
- Type consistency: `IntervalScheduler`, `ReminderKind`, `AutomaticPetAction`, `restBlockingDurationSeconds`, `restBlockingScalePercent`, `waterIntervalMinutes`, and `bubbleDurationSeconds` are used consistently across tasks.

# Mac Pet Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS desktop pet app with a draggable, resizable pixel Siamese cat, light interaction, configurable rest reminders, and persistent settings.

**Architecture:** Use a SwiftPM macOS executable app with SwiftUI for app state, views, settings, and sprite presentation. Use one narrow AppKit bridge for the transparent always-on-top pet window. Keep logic testable by isolating settings, the pet state machine, reminder scheduling, and sprite animation away from AppKit.

**Tech Stack:** Swift 5.9+, SwiftUI, AppKit, UserNotifications, XCTest, Swift Package Manager.

---

## File Structure

Create this structure from the empty repository:

```text
Package.swift
.codex/environments/environment.toml
script/build_and_run.sh
Sources/MacPet/App/MacPetApp.swift
Sources/MacPet/App/AppDelegate.swift
Sources/MacPet/App/AppRuntime.swift
Sources/MacPet/Animation/SpriteAnimator.swift
Sources/MacPet/Animation/PixelCatPlaceholderView.swift
Sources/MacPet/Models/PetState.swift
Sources/MacPet/Models/PetPreferences.swift
Sources/MacPet/Services/ReminderScheduler.swift
Sources/MacPet/Services/NotificationClient.swift
Sources/MacPet/State/PetStateMachine.swift
Sources/MacPet/Stores/SettingsStore.swift
Sources/MacPet/Views/BubbleView.swift
Sources/MacPet/Views/PetView.swift
Sources/MacPet/Views/SettingsView.swift
Sources/MacPet/Windowing/PetWindowController.swift
Tests/MacPetTests/PetStateMachineTests.swift
Tests/MacPetTests/ReminderSchedulerTests.swift
Tests/MacPetTests/SettingsStoreTests.swift
Tests/MacPetTests/SpriteAnimatorTests.swift
```

Responsibilities:

- `Package.swift`: SwiftPM package, executable target, test target, macOS platform.
- `.codex/environments/environment.toml`: Codex run-button config.
- `script/build_and_run.sh`: local build/run entry point.
- `MacPetApp.swift`: SwiftUI app entry, menu bar extra, settings scene.
- `AppDelegate.swift`: activation policy and pet window lifecycle setup.
- `AppRuntime.swift`: app-wide runtime object that owns settings, pet state, scheduler, notification client, and window controller.
- `SpriteAnimator.swift`: pure frame-selection logic from state and elapsed time.
- `PixelCatPlaceholderView.swift`: temporary pixel-art cat drawing until final sprite images exist.
- `PetState.swift`: state enum and event enum.
- `PetPreferences.swift`: value model for persisted settings.
- `ReminderScheduler.swift`: deterministic reminder timer logic.
- `NotificationClient.swift`: macOS notification permission and dispatch wrapper.
- `PetStateMachine.swift`: pure state transition logic.
- `SettingsStore.swift`: observable settings persisted to `UserDefaults`.
- `BubbleView.swift`: speech bubble UI.
- `PetView.swift`: interactive cat UI and state rendering.
- `SettingsView.swift`: native settings controls.
- `PetWindowController.swift`: transparent borderless floating window bridge.
- Test files: unit tests for pure logic and persistence.

---

### Task 1: Scaffold SwiftPM macOS App

**Files:**
- Create: `Package.swift`
- Create: `.codex/environments/environment.toml`
- Create: `script/build_and_run.sh`
- Create: `Sources/MacPet/App/MacPetApp.swift`

- [ ] **Step 1: Create the package manifest**

Create `Package.swift`:

```swift
// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MacPet",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacPet", targets: ["MacPet"])
    ],
    targets: [
        .executableTarget(
            name: "MacPet",
            path: "Sources/MacPet"
        ),
        .testTarget(
            name: "MacPetTests",
            dependencies: ["MacPet"],
            path: "Tests/MacPetTests"
        )
    ]
)
```

- [ ] **Step 2: Add the Codex run-button environment**

Create `.codex/environments/environment.toml`:

```toml
[commands]
run = "script/build_and_run.sh"
```

- [ ] **Step 3: Add the build-and-run script**

Create `script/build_and_run.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
swift run MacPet
```

Then run:

```bash
chmod +x script/build_and_run.sh
```

Expected: command exits with no output.

- [ ] **Step 4: Add a minimal SwiftUI app entry point**

Create `Sources/MacPet/App/MacPetApp.swift`:

```swift
import SwiftUI

@main
struct MacPetApp: App {
    var body: some Scene {
        WindowGroup("Mac Pet") {
            Text("Mac Pet is starting up.")
                .frame(width: 320, height: 180)
        }
    }
}
```

- [ ] **Step 5: Build the app**

Run:

```bash
swift build
```

Expected: build succeeds with `Build complete!`.

- [ ] **Step 6: Commit**

Run:

```bash
git add Package.swift .codex/environments/environment.toml script/build_and_run.sh Sources/MacPet/App/MacPetApp.swift
git commit -m "feat: scaffold mac pet app"
```

Expected: commit succeeds.

---

### Task 2: Add Preferences And Settings Persistence

**Files:**
- Create: `Sources/MacPet/Models/PetPreferences.swift`
- Create: `Sources/MacPet/Stores/SettingsStore.swift`
- Create: `Tests/MacPetTests/SettingsStoreTests.swift`

- [ ] **Step 1: Write failing settings persistence tests**

Create `Tests/MacPetTests/SettingsStoreTests.swift`:

```swift
import XCTest
@testable import MacPet

final class SettingsStoreTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "MacPetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    func testDefaultsMatchProductDecisions() {
        let store = SettingsStore(defaults: makeDefaults())

        XCTAssertEqual(store.preferences.reminderIntervalMinutes, 25)
        XCTAssertEqual(store.preferences.sleepDelayMinutes, 30)
        XCTAssertEqual(store.preferences.petScale, 1.0)
        XCTAssertTrue(store.preferences.showPetOnLaunch)
        XCTAssertFalse(store.preferences.systemNotificationsEnabled)
        XCTAssertFalse(store.preferences.lowerDistractionMode)
    }

    func testSavesCustomReminderIntervalAndScale() {
        let defaults = makeDefaults()
        var store = SettingsStore(defaults: defaults)

        store.updateReminderInterval(minutes: 45)
        store.updatePetScale(1.6)

        let reloaded = SettingsStore(defaults: defaults)
        XCTAssertEqual(reloaded.preferences.reminderIntervalMinutes, 45)
        XCTAssertEqual(reloaded.preferences.petScale, 1.6)
    }

    func testClampsInvalidValues() {
        var store = SettingsStore(defaults: makeDefaults())

        store.updateReminderInterval(minutes: 0)
        store.updateSleepDelay(minutes: -4)
        store.updatePetScale(9.0)

        XCTAssertEqual(store.preferences.reminderIntervalMinutes, 1)
        XCTAssertEqual(store.preferences.sleepDelayMinutes, 1)
        XCTAssertEqual(store.preferences.petScale, 3.0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter SettingsStoreTests
```

Expected: FAIL because `PetPreferences` and `SettingsStore` do not exist.

- [ ] **Step 3: Add the preferences value model**

Create `Sources/MacPet/Models/PetPreferences.swift`:

```swift
import Foundation

public struct PetPreferences: Equatable, Sendable {
    public var reminderIntervalMinutes: Int
    public var sleepDelayMinutes: Int
    public var petScale: Double
    public var showPetOnLaunch: Bool
    public var systemNotificationsEnabled: Bool
    public var lowerDistractionMode: Bool

    public init(
        reminderIntervalMinutes: Int = 25,
        sleepDelayMinutes: Int = 30,
        petScale: Double = 1.0,
        showPetOnLaunch: Bool = true,
        systemNotificationsEnabled: Bool = false,
        lowerDistractionMode: Bool = false
    ) {
        self.reminderIntervalMinutes = max(1, reminderIntervalMinutes)
        self.sleepDelayMinutes = max(1, sleepDelayMinutes)
        self.petScale = min(max(petScale, 0.5), 3.0)
        self.showPetOnLaunch = showPetOnLaunch
        self.systemNotificationsEnabled = systemNotificationsEnabled
        self.lowerDistractionMode = lowerDistractionMode
    }
}
```

- [ ] **Step 4: Add the settings store**

Create `Sources/MacPet/Stores/SettingsStore.swift`:

```swift
import Foundation
import Observation

@Observable
public final class SettingsStore {
    private enum Key {
        static let reminderIntervalMinutes = "reminderIntervalMinutes"
        static let sleepDelayMinutes = "sleepDelayMinutes"
        static let petScale = "petScale"
        static let showPetOnLaunch = "showPetOnLaunch"
        static let systemNotificationsEnabled = "systemNotificationsEnabled"
        static let lowerDistractionMode = "lowerDistractionMode"
    }

    public private(set) var preferences: PetPreferences

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.preferences = PetPreferences(
            reminderIntervalMinutes: defaults.object(forKey: Key.reminderIntervalMinutes) as? Int ?? 25,
            sleepDelayMinutes: defaults.object(forKey: Key.sleepDelayMinutes) as? Int ?? 30,
            petScale: defaults.object(forKey: Key.petScale) as? Double ?? 1.0,
            showPetOnLaunch: defaults.object(forKey: Key.showPetOnLaunch) as? Bool ?? true,
            systemNotificationsEnabled: defaults.object(forKey: Key.systemNotificationsEnabled) as? Bool ?? false,
            lowerDistractionMode: defaults.object(forKey: Key.lowerDistractionMode) as? Bool ?? false
        )
        persist()
    }

    public func updateReminderInterval(minutes: Int) {
        preferences.reminderIntervalMinutes = max(1, minutes)
        persist()
    }

    public func updateSleepDelay(minutes: Int) {
        preferences.sleepDelayMinutes = max(1, minutes)
        persist()
    }

    public func updatePetScale(_ scale: Double) {
        preferences.petScale = min(max(scale, 0.5), 3.0)
        persist()
    }

    public func updateShowPetOnLaunch(_ enabled: Bool) {
        preferences.showPetOnLaunch = enabled
        persist()
    }

    public func updateSystemNotificationsEnabled(_ enabled: Bool) {
        preferences.systemNotificationsEnabled = enabled
        persist()
    }

    public func updateLowerDistractionMode(_ enabled: Bool) {
        preferences.lowerDistractionMode = enabled
        persist()
    }

    private func persist() {
        defaults.set(preferences.reminderIntervalMinutes, forKey: Key.reminderIntervalMinutes)
        defaults.set(preferences.sleepDelayMinutes, forKey: Key.sleepDelayMinutes)
        defaults.set(preferences.petScale, forKey: Key.petScale)
        defaults.set(preferences.showPetOnLaunch, forKey: Key.showPetOnLaunch)
        defaults.set(preferences.systemNotificationsEnabled, forKey: Key.systemNotificationsEnabled)
        defaults.set(preferences.lowerDistractionMode, forKey: Key.lowerDistractionMode)
    }
}
```

- [ ] **Step 5: Run settings tests**

Run:

```bash
swift test --filter SettingsStoreTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/MacPet/Models/PetPreferences.swift Sources/MacPet/Stores/SettingsStore.swift Tests/MacPetTests/SettingsStoreTests.swift
git commit -m "feat: persist pet settings"
```

Expected: commit succeeds.

---

### Task 3: Add Pet State Machine

**Files:**
- Create: `Sources/MacPet/Models/PetState.swift`
- Create: `Sources/MacPet/State/PetStateMachine.swift`
- Create: `Tests/MacPetTests/PetStateMachineTests.swift`

- [ ] **Step 1: Write failing state machine tests**

Create `Tests/MacPetTests/PetStateMachineTests.swift`:

```swift
import XCTest
@testable import MacPet

final class PetStateMachineTests: XCTestCase {
    func testStartsIdle() {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        XCTAssertEqual(machine.state, .idle)
        XCTAssertNil(machine.bubbleText)
    }

    func testFallsAsleepAfterInactivity() {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))

        XCTAssertEqual(machine.state, .sleeping)
    }

    func testInteractionWakesSleepingPet() {
        var current = Date(timeIntervalSince1970: 0)
        let machine = PetStateMachine(now: { current })

        current = Date(timeIntervalSince1970: 31 * 60)
        machine.tick(preferences: PetPreferences(sleepDelayMinutes: 30))
        machine.handle(.clicked)

        XCTAssertEqual(machine.state, .waking)
    }

    func testClickAwakePetTriggersPetting() {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.clicked)

        XCTAssertEqual(machine.state, .petting)
    }

    func testReminderShowsBubble() {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired)

        XCTAssertEqual(machine.state, .reminding)
        XCTAssertEqual(machine.bubbleText, "休息一下吧")
    }

    func testDismissReminderClearsBubbleAndReturnsIdle() {
        let machine = PetStateMachine(now: { Date(timeIntervalSince1970: 0) })

        machine.handle(.reminderFired)
        machine.handle(.dismissedReminder)

        XCTAssertEqual(machine.state, .idle)
        XCTAssertNil(machine.bubbleText)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter PetStateMachineTests
```

Expected: FAIL because `PetStateMachine`, `PetState`, and `PetEvent` do not exist.

- [ ] **Step 3: Add pet state and event models**

Create `Sources/MacPet/Models/PetState.swift`:

```swift
import Foundation

public enum PetState: Equatable, Sendable {
    case idle
    case blink
    case sleeping
    case waking
    case petting
    case reminding
}

public enum PetEvent: Equatable, Sendable {
    case clicked
    case dragged
    case controlsOpened
    case reminderFired
    case dismissedReminder
    case animationCompleted
}
```

- [ ] **Step 4: Add the pet state machine**

Create `Sources/MacPet/State/PetStateMachine.swift`:

```swift
import Foundation
import Observation

@Observable
public final class PetStateMachine {
    public private(set) var state: PetState = .idle
    public private(set) var bubbleText: String?

    private var lastInteractionAt: Date
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
        self.lastInteractionAt = now()
    }

    public func tick(preferences: PetPreferences) {
        guard state != .reminding else { return }
        let inactiveSeconds = now().timeIntervalSince(lastInteractionAt)
        let sleepDelaySeconds = TimeInterval(preferences.sleepDelayMinutes * 60)

        if inactiveSeconds >= sleepDelaySeconds {
            state = .sleeping
            bubbleText = nil
        }
    }

    public func handle(_ event: PetEvent) {
        switch event {
        case .clicked:
            recordInteraction()
            state = state == .sleeping ? .waking : .petting
            bubbleText = nil
        case .dragged, .controlsOpened:
            recordInteraction()
            state = state == .sleeping ? .waking : .idle
            bubbleText = nil
        case .reminderFired:
            state = .reminding
            bubbleText = "休息一下吧"
        case .dismissedReminder:
            recordInteraction()
            state = .idle
            bubbleText = nil
        case .animationCompleted:
            if state == .waking || state == .petting || state == .blink {
                state = .idle
            }
        }
    }

    private func recordInteraction() {
        lastInteractionAt = now()
    }
}
```

- [ ] **Step 5: Run state machine tests**

Run:

```bash
swift test --filter PetStateMachineTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/MacPet/Models/PetState.swift Sources/MacPet/State/PetStateMachine.swift Tests/MacPetTests/PetStateMachineTests.swift
git commit -m "feat: add pet state machine"
```

Expected: commit succeeds.

---

### Task 4: Add Reminder Scheduler And Notifications

**Files:**
- Create: `Sources/MacPet/Services/ReminderScheduler.swift`
- Create: `Sources/MacPet/Services/NotificationClient.swift`
- Create: `Tests/MacPetTests/ReminderSchedulerTests.swift`

- [ ] **Step 1: Write failing reminder scheduler tests**

Create `Tests/MacPetTests/ReminderSchedulerTests.swift`:

```swift
import XCTest
@testable import MacPet

final class ReminderSchedulerTests: XCTestCase {
    func testDoesNotFireBeforeInterval() {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = ReminderScheduler(now: { current })
        var firedCount = 0
        scheduler.onReminder = { firedCount += 1 }

        scheduler.start(intervalMinutes: 25)
        current = Date(timeIntervalSince1970: 24 * 60)
        scheduler.tick()

        XCTAssertEqual(firedCount, 0)
    }

    func testFiresAtCustomInterval() {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = ReminderScheduler(now: { current })
        var firedCount = 0
        scheduler.onReminder = { firedCount += 1 }

        scheduler.start(intervalMinutes: 45)
        current = Date(timeIntervalSince1970: 45 * 60)
        scheduler.tick()

        XCTAssertEqual(firedCount, 1)
        XCTAssertTrue(scheduler.isReminderActive)
    }

    func testDismissRestartsTimer() {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = ReminderScheduler(now: { current })
        var firedCount = 0
        scheduler.onReminder = { firedCount += 1 }

        scheduler.start(intervalMinutes: 10)
        current = Date(timeIntervalSince1970: 10 * 60)
        scheduler.tick()
        scheduler.dismissActiveReminder()
        current = Date(timeIntervalSince1970: 19 * 60)
        scheduler.tick()
        XCTAssertEqual(firedCount, 1)

        current = Date(timeIntervalSince1970: 20 * 60)
        scheduler.tick()
        XCTAssertEqual(firedCount, 2)
    }

    func testUpdatingIntervalRestartsFromNow() {
        var current = Date(timeIntervalSince1970: 0)
        let scheduler = ReminderScheduler(now: { current })
        var firedCount = 0
        scheduler.onReminder = { firedCount += 1 }

        scheduler.start(intervalMinutes: 25)
        current = Date(timeIntervalSince1970: 20 * 60)
        scheduler.updateInterval(minutes: 5)
        current = Date(timeIntervalSince1970: 24 * 60)
        scheduler.tick()
        XCTAssertEqual(firedCount, 0)

        current = Date(timeIntervalSince1970: 25 * 60)
        scheduler.tick()
        XCTAssertEqual(firedCount, 1)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter ReminderSchedulerTests
```

Expected: FAIL because `ReminderScheduler` does not exist.

- [ ] **Step 3: Add notification client**

Create `Sources/MacPet/Services/NotificationClient.swift`:

```swift
import Foundation
import UserNotifications

public protocol NotificationClientProtocol {
    func requestAuthorization() async throws -> Bool
    func sendRestReminder()
}

public struct NotificationClient: NotificationClientProtocol {
    public init() {}

    public func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    public func sendRestReminder() {
        let content = UNMutableNotificationContent()
        content.title = "Mac Pet"
        content.body = "休息一下吧"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "mac-pet-rest-reminder-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] **Step 4: Add reminder scheduler**

Create `Sources/MacPet/Services/ReminderScheduler.swift`:

```swift
import Foundation
import Observation

@Observable
public final class ReminderScheduler {
    public var onReminder: (() -> Void)?
    public private(set) var isReminderActive = false

    private var intervalMinutes: Int = 25
    private var nextReminderAt: Date?
    private let now: () -> Date

    public init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    public func start(intervalMinutes: Int) {
        self.intervalMinutes = max(1, intervalMinutes)
        isReminderActive = false
        scheduleNext(from: now())
    }

    public func updateInterval(minutes: Int) {
        intervalMinutes = max(1, minutes)
        isReminderActive = false
        scheduleNext(from: now())
    }

    public func tick() {
        guard !isReminderActive, let nextReminderAt else { return }
        guard now() >= nextReminderAt else { return }

        isReminderActive = true
        onReminder?()
    }

    public func dismissActiveReminder() {
        isReminderActive = false
        scheduleNext(from: now())
    }

    private func scheduleNext(from date: Date) {
        nextReminderAt = date.addingTimeInterval(TimeInterval(intervalMinutes * 60))
    }
}
```

- [ ] **Step 5: Run reminder tests**

Run:

```bash
swift test --filter ReminderSchedulerTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/MacPet/Services/ReminderScheduler.swift Sources/MacPet/Services/NotificationClient.swift Tests/MacPetTests/ReminderSchedulerTests.swift
git commit -m "feat: add reminder scheduler"
```

Expected: commit succeeds.

---

### Task 5: Add Sprite Animation Logic And Placeholder Cat

**Files:**
- Create: `Sources/MacPet/Animation/SpriteAnimator.swift`
- Create: `Sources/MacPet/Animation/PixelCatPlaceholderView.swift`
- Create: `Tests/MacPetTests/SpriteAnimatorTests.swift`

- [ ] **Step 1: Write failing sprite animator tests**

Create `Tests/MacPetTests/SpriteAnimatorTests.swift`:

```swift
import XCTest
@testable import MacPet

final class SpriteAnimatorTests: XCTestCase {
    func testIdleFramesCycle() {
        let animator = SpriteAnimator()

        XCTAssertEqual(animator.frame(for: .idle, elapsed: 0, lowerDistractionMode: false), "idle-0")
        XCTAssertEqual(animator.frame(for: .idle, elapsed: 0.5, lowerDistractionMode: false), "idle-1")
    }

    func testSleepingUsesSleepFrames() {
        let animator = SpriteAnimator()

        XCTAssertEqual(animator.frame(for: .sleeping, elapsed: 0, lowerDistractionMode: false), "sleep-0")
        XCTAssertEqual(animator.frame(for: .sleeping, elapsed: 1.0, lowerDistractionMode: false), "sleep-1")
    }

    func testLowerDistractionUsesSlowerIdleFrameTiming() {
        let animator = SpriteAnimator()

        XCTAssertEqual(animator.frame(for: .idle, elapsed: 0.5, lowerDistractionMode: true), "idle-0")
        XCTAssertEqual(animator.frame(for: .idle, elapsed: 2.0, lowerDistractionMode: true), "idle-1")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
swift test --filter SpriteAnimatorTests
```

Expected: FAIL because `SpriteAnimator` does not exist.

- [ ] **Step 3: Add sprite animator**

Create `Sources/MacPet/Animation/SpriteAnimator.swift`:

```swift
import Foundation

public struct SpriteAnimator: Sendable {
    public init() {}

    public func frame(for state: PetState, elapsed: TimeInterval, lowerDistractionMode: Bool) -> String {
        let frames = frames(for: state)
        let frameDuration = duration(for: state, lowerDistractionMode: lowerDistractionMode)
        let index = Int(elapsed / frameDuration) % frames.count
        return frames[index]
    }

    private func frames(for state: PetState) -> [String] {
        switch state {
        case .idle:
            return ["idle-0", "idle-1", "tail-sway-0", "tail-sway-1"]
        case .blink:
            return ["blink-0", "blink-1"]
        case .sleeping:
            return ["sleep-0", "sleep-1"]
        case .waking:
            return ["wake-0", "wake-1"]
        case .petting:
            return ["petting-0", "petting-1"]
        case .reminding:
            return ["reminder-0", "reminder-1"]
        }
    }

    private func duration(for state: PetState, lowerDistractionMode: Bool) -> TimeInterval {
        if lowerDistractionMode && state == .idle {
            return 2.0
        }

        switch state {
        case .idle:
            return 0.5
        case .blink, .waking, .petting, .reminding:
            return 0.25
        case .sleeping:
            return 1.0
        }
    }
}
```

- [ ] **Step 4: Add a temporary pixel cat view**

Create `Sources/MacPet/Animation/PixelCatPlaceholderView.swift`:

```swift
import SwiftUI

public struct PixelCatPlaceholderView: View {
    let frameName: String

    public init(frameName: String) {
        self.frameName = frameName
    }

    public var body: some View {
        ZStack {
            bodyShape
            face
            ears
            legs
            tail
        }
        .aspectRatio(1, contentMode: .fit)
        .drawingGroup(opaque: false, colorMode: .nonLinear)
        .accessibilityLabel("Pixel Siamese cat")
    }

    private var bodyShape: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.95, green: 0.88, blue: 0.74))
                .frame(width: 76, height: 54)
                .offset(x: 10, y: 18)

            Circle()
                .fill(Color(red: 0.94, green: 0.86, blue: 0.70))
                .frame(width: 64, height: 64)
                .offset(x: -18, y: -18)

            Circle()
                .stroke(Color(red: 0.16, green: 0.09, blue: 0.18), lineWidth: 4)
                .frame(width: 64, height: 64)
                .offset(x: -18, y: -18)
        }
    }

    private var face: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.47, green: 0.36, blue: 0.30))
                .frame(width: 42, height: 38)
                .offset(x: -18, y: -12)

            HStack(spacing: 12) {
                Circle().fill(Color(red: 0.22, green: 0.72, blue: 0.95)).frame(width: 10, height: 14)
                Circle().fill(Color(red: 0.22, green: 0.72, blue: 0.95)).frame(width: 10, height: 14)
            }
            .offset(x: -18, y: -16)

            Text("⌣")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .offset(x: -18, y: -2)
        }
    }

    private var ears: some View {
        ZStack {
            Triangle()
                .fill(Color(red: 0.28, green: 0.20, blue: 0.18))
                .frame(width: 28, height: 34)
                .offset(x: -42, y: -50)
            Triangle()
                .fill(Color(red: 0.28, green: 0.20, blue: 0.18))
                .frame(width: 28, height: 34)
                .offset(x: 4, y: -50)
        }
    }

    private var legs: some View {
        HStack(spacing: 10) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(red: 0.28, green: 0.20, blue: 0.18))
                    .frame(width: 12, height: 28)
            }
        }
        .offset(x: 10, y: 54)
    }

    private var tail: some View {
        Capsule()
            .stroke(Color(red: 0.28, green: 0.20, blue: 0.18), lineWidth: 12)
            .frame(width: 28, height: 76)
            .rotationEffect(.degrees(frameName.contains("tail-sway-1") ? -18 : -8))
            .offset(x: 54, y: -2)
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
```

- [ ] **Step 5: Run sprite tests**

Run:

```bash
swift test --filter SpriteAnimatorTests
```

Expected: PASS.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/MacPet/Animation/SpriteAnimator.swift Sources/MacPet/Animation/PixelCatPlaceholderView.swift Tests/MacPetTests/SpriteAnimatorTests.swift
git commit -m "feat: add sprite animation layer"
```

Expected: commit succeeds.

---

### Task 6: Add Pet View, Bubble, And Settings UI

**Files:**
- Create: `Sources/MacPet/Views/BubbleView.swift`
- Create: `Sources/MacPet/Views/PetView.swift`
- Create: `Sources/MacPet/Views/SettingsView.swift`
- Modify: `Sources/MacPet/App/MacPetApp.swift`

- [ ] **Step 1: Add speech bubble UI**

Create `Sources/MacPet/Views/BubbleView.swift`:

```swift
import SwiftUI

public struct BubbleView: View {
    let text: String
    let onDismiss: () -> Void

    public init(text: String, onDismiss: @escaping () -> Void) {
        self.text = text
        self.onDismiss = onDismiss
    }

    public var body: some View {
        Button(action: onDismiss) {
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
    }
}
```

- [ ] **Step 2: Add pet view**

Create `Sources/MacPet/Views/PetView.swift`:

```swift
import SwiftUI

public struct PetView: View {
    @Bindable var settings: SettingsStore
    @Bindable var stateMachine: PetStateMachine
    let scheduler: ReminderScheduler

    private let animator = SpriteAnimator()

    public init(settings: SettingsStore, stateMachine: PetStateMachine, scheduler: ReminderScheduler) {
        self.settings = settings
        self.stateMachine = stateMachine
        self.scheduler = scheduler
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 0.25)) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            let frame = animator.frame(
                for: stateMachine.state,
                elapsed: elapsed,
                lowerDistractionMode: settings.preferences.lowerDistractionMode
            )

            VStack(spacing: 6) {
                if let bubble = stateMachine.bubbleText, !settings.preferences.lowerDistractionMode {
                    BubbleView(text: bubble) {
                        scheduler.dismissActiveReminder()
                        stateMachine.handle(.dismissedReminder)
                    }
                }

                PixelCatPlaceholderView(frameName: frame)
                    .frame(
                        width: 128 * settings.preferences.petScale,
                        height: 128 * settings.preferences.petScale
                    )
                    .onTapGesture {
                        if stateMachine.state == .reminding {
                            scheduler.dismissActiveReminder()
                            stateMachine.handle(.dismissedReminder)
                        } else {
                            stateMachine.handle(.clicked)
                        }
                    }
            }
            .padding(12)
        }
    }
}
```

- [ ] **Step 3: Add settings view**

Create `Sources/MacPet/Views/SettingsView.swift`:

```swift
import SwiftUI

public struct SettingsView: View {
    @Bindable var settings: SettingsStore

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        Form {
            Section("Pet") {
                Slider(
                    value: Binding(
                        get: { settings.preferences.petScale },
                        set: { settings.updatePetScale($0) }
                    ),
                    in: 0.5...3.0,
                    step: 0.1
                ) {
                    Text("Size")
                } minimumValueLabel: {
                    Text("Small")
                } maximumValueLabel: {
                    Text("Large")
                }

                Toggle(
                    "Show pet on launch",
                    isOn: Binding(
                        get: { settings.preferences.showPetOnLaunch },
                        set: { settings.updateShowPetOnLaunch($0) }
                    )
                )

                Toggle(
                    "Lower-distraction mode",
                    isOn: Binding(
                        get: { settings.preferences.lowerDistractionMode },
                        set: { settings.updateLowerDistractionMode($0) }
                    )
                )
            }

            Section("Reminders") {
                Stepper(
                    "Reminder every \(settings.preferences.reminderIntervalMinutes) minutes",
                    value: Binding(
                        get: { settings.preferences.reminderIntervalMinutes },
                        set: { settings.updateReminderInterval(minutes: $0) }
                    ),
                    in: 1...240
                )

                Stepper(
                    "Sleep after \(settings.preferences.sleepDelayMinutes) minutes",
                    value: Binding(
                        get: { settings.preferences.sleepDelayMinutes },
                        set: { settings.updateSleepDelay(minutes: $0) }
                    ),
                    in: 1...240
                )

                Toggle(
                    "Use macOS notifications",
                    isOn: Binding(
                        get: { settings.preferences.systemNotificationsEnabled },
                        set: { settings.updateSystemNotificationsEnabled($0) }
                    )
                )
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
```

- [ ] **Step 4: Wire settings scene into the app entry**

Replace `Sources/MacPet/App/MacPetApp.swift` with:

```swift
import SwiftUI

@main
struct MacPetApp: App {
    @State private var settings = SettingsStore()
    @State private var stateMachine = PetStateMachine()
    @State private var scheduler = ReminderScheduler()

    var body: some Scene {
        WindowGroup("Mac Pet") {
            PetView(settings: settings, stateMachine: stateMachine, scheduler: scheduler)
        }

        Settings {
            SettingsView(settings: settings)
        }
    }
}
```

- [ ] **Step 5: Build and test**

Run:

```bash
swift test
swift build
```

Expected: tests pass and build succeeds.

- [ ] **Step 6: Commit**

Run:

```bash
git add Sources/MacPet/Views/BubbleView.swift Sources/MacPet/Views/PetView.swift Sources/MacPet/Views/SettingsView.swift Sources/MacPet/App/MacPetApp.swift
git commit -m "feat: add pet and settings views"
```

Expected: commit succeeds.

---

### Task 7: Add Floating Pet Window, Menu Bar, And App Lifecycle

**Files:**
- Create: `Sources/MacPet/App/AppDelegate.swift`
- Create: `Sources/MacPet/App/AppRuntime.swift`
- Create: `Sources/MacPet/Windowing/PetWindowController.swift`
- Modify: `Sources/MacPet/App/MacPetApp.swift`

- [ ] **Step 1: Add the AppKit floating window controller**

Create `Sources/MacPet/Windowing/PetWindowController.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
public final class PetWindowController {
    private var window: NSWindow?
    private let frameDefaultsKey = "petWindowFrame"

    public init() {}

    public func show<Content: View>(rootView: Content, scale: Double) {
        if let window {
            window.makeKeyAndOrderFront(nil)
            return
        }

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor

        let frame = restoredFrame(defaultScale: scale)
        let window = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.ignoresMouseEvents = false
        window.title = "Mac Pet"
        window.orderFrontRegardless()

        NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveFrame()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResizeNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.saveFrame()
            }
        }

        self.window = window
    }

    public func hide() {
        window?.orderOut(nil)
    }

    public func close() {
        saveFrame()
        window?.close()
        window = nil
    }

    public func updateScale(_ scale: Double) {
        guard let window else { return }
        let side = 176 * scale
        var frame = window.frame
        frame.size = CGSize(width: side, height: side + 48)
        window.setFrame(frame, display: true)
        saveFrame()
    }

    public func saveFrame() {
        guard let frame = window?.frame else { return }
        UserDefaults.standard.set(NSStringFromRect(frame), forKey: frameDefaultsKey)
    }

    private func restoredFrame(defaultScale: Double) -> CGRect {
        if let raw = UserDefaults.standard.string(forKey: frameDefaultsKey) {
            let frame = NSRectFromString(raw)
            if frame.width > 20, frame.height > 20 {
                return frame
            }
        }

        let side = 176 * defaultScale
        let screenFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 100, y: 100, width: 1200, height: 800)
        return CGRect(
            x: screenFrame.maxX - side - 80,
            y: screenFrame.minY + 120,
            width: side,
            height: side + 48
        )
    }
}
```

- [ ] **Step 2: Add app delegate**

Create `Sources/MacPet/App/AppDelegate.swift`:

```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.post(name: .macPetWillTerminate, object: nil)
    }
}

extension Notification.Name {
    static let macPetWillTerminate = Notification.Name("macPetWillTerminate")
}
```

- [ ] **Step 3: Add app runtime**

Create `Sources/MacPet/App/AppRuntime.swift`:

```swift
import Foundation
import Observation

@MainActor
@Observable
final class AppRuntime {
    let settings = SettingsStore()
    let stateMachine = PetStateMachine()
    let scheduler = ReminderScheduler()

    private let petWindowController = PetWindowController()
    private let notificationClient: NotificationClientProtocol
    private var runtimeTask: Task<Void, Never>?

    init(notificationClient: NotificationClientProtocol = NotificationClient()) {
        self.notificationClient = notificationClient
    }

    func start() {
        guard runtimeTask == nil else { return }

        scheduler.onReminder = { [weak self] in
            guard let self else { return }
            stateMachine.handle(.reminderFired)
            if settings.preferences.systemNotificationsEnabled {
                notificationClient.sendRestReminder()
            }
        }
        scheduler.start(intervalMinutes: settings.preferences.reminderIntervalMinutes)

        if settings.preferences.showPetOnLaunch {
            showPet()
        }

        runtimeTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                scheduler.tick()
                stateMachine.tick(preferences: settings.preferences)
            }
        }
    }

    func stop() {
        runtimeTask?.cancel()
        runtimeTask = nil
        petWindowController.close()
    }

    func showPet() {
        petWindowController.show(
            rootView: PetView(settings: settings, stateMachine: stateMachine, scheduler: scheduler),
            scale: settings.preferences.petScale
        )
        stateMachine.handle(.controlsOpened)
    }

    func hidePet() {
        petWindowController.hide()
    }

    func updatePetScale(_ scale: Double) {
        settings.updatePetScale(scale)
        petWindowController.updateScale(scale)
    }

    func updateReminderInterval(minutes: Int) {
        settings.updateReminderInterval(minutes: minutes)
        scheduler.updateInterval(minutes: minutes)
    }

    func updateSystemNotificationsEnabled(_ enabled: Bool) {
        settings.updateSystemNotificationsEnabled(enabled)
        if enabled {
            Task {
                _ = try? await notificationClient.requestAuthorization()
            }
        }
    }
}
```

- [ ] **Step 4: Replace app entry with menu bar and floating window lifecycle**

Replace `Sources/MacPet/App/MacPetApp.swift` with:

```swift
import AppKit
import SwiftUI

@main
@MainActor
struct MacPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var runtime: AppRuntime

    init() {
        let runtime = AppRuntime()
        _runtime = State(initialValue: runtime)
        runtime.start()
    }

    var body: some Scene {
        MenuBarExtra("Mac Pet", systemImage: "pawprint.fill") {
            Button("Show Pet") {
                runtime.showPet()
            }
            Button("Hide Pet") {
                runtime.hidePet()
            }
            Divider()
            Toggle(
                "Lower Distraction",
                isOn: Binding(
                    get: { runtime.settings.preferences.lowerDistractionMode },
                    set: { runtime.settings.updateLowerDistractionMode($0) }
                )
            )
            SettingsLink {
                Text("Settings...")
            }
            Divider()
            Button("Quit") {
                runtime.stop()
                NSApp.terminate(nil)
            }
        }

        Settings {
            SettingsView(settings: runtime.settings)
                .onChange(of: runtime.settings.preferences.petScale) { _, scale in
                    runtime.updatePetScale(scale)
                }
                .onChange(of: runtime.settings.preferences.reminderIntervalMinutes) { _, minutes in
                    runtime.updateReminderInterval(minutes: minutes)
                }
                .onChange(of: runtime.settings.preferences.systemNotificationsEnabled) { _, enabled in
                    runtime.updateSystemNotificationsEnabled(enabled)
                }
        }
    }
}
```

- [ ] **Step 5: Keep settings view as the native controls surface**

Replace `Sources/MacPet/Views/SettingsView.swift` with:

```swift
import SwiftUI

public struct SettingsView: View {
    @Bindable var settings: SettingsStore

    public init(settings: SettingsStore) {
        self.settings = settings
    }

    public var body: some View {
        Form {
            Section("Pet") {
                Slider(
                    value: Binding(
                        get: { settings.preferences.petScale },
                        set: { settings.updatePetScale($0) }
                    ),
                    in: 0.5...3.0,
                    step: 0.1
                ) {
                    Text("Size")
                } minimumValueLabel: {
                    Text("Small")
                } maximumValueLabel: {
                    Text("Large")
                }

                Toggle(
                    "Show pet on launch",
                    isOn: Binding(
                        get: { settings.preferences.showPetOnLaunch },
                        set: { settings.updateShowPetOnLaunch($0) }
                    )
                )

                Toggle(
                    "Lower-distraction mode",
                    isOn: Binding(
                        get: { settings.preferences.lowerDistractionMode },
                        set: { settings.updateLowerDistractionMode($0) }
                    )
                )
            }

            Section("Reminders") {
                Stepper(
                    "Reminder every \(settings.preferences.reminderIntervalMinutes) minutes",
                    value: Binding(
                        get: { settings.preferences.reminderIntervalMinutes },
                        set: { settings.updateReminderInterval(minutes: $0) }
                    ),
                    in: 1...240
                )

                Stepper(
                    "Sleep after \(settings.preferences.sleepDelayMinutes) minutes",
                    value: Binding(
                        get: { settings.preferences.sleepDelayMinutes },
                        set: { settings.updateSleepDelay(minutes: $0) }
                    ),
                    in: 1...240
                )

                Toggle(
                    "Use macOS notifications",
                    isOn: Binding(
                        get: { settings.preferences.systemNotificationsEnabled },
                        set: { settings.updateSystemNotificationsEnabled($0) }
                    )
                )
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
    }
}
```

- [ ] **Step 6: Build**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 7: Commit**

Run:

```bash
git add Sources/MacPet/App/AppDelegate.swift Sources/MacPet/App/AppRuntime.swift Sources/MacPet/Windowing/PetWindowController.swift Sources/MacPet/App/MacPetApp.swift Sources/MacPet/Views/SettingsView.swift
git commit -m "feat: add floating pet window"
```

Expected: commit succeeds.

---

### Task 8: Verify End-To-End Behavior And Tighten MVP

**Files:**
- Read: `Sources/MacPet/App/MacPetApp.swift`
- Read: `Sources/MacPet/Views/PetView.swift`
- Read: `Sources/MacPet/Views/SettingsView.swift`
- Read: `Sources/MacPet/Windowing/PetWindowController.swift`
- Read: `Sources/MacPet/Stores/SettingsStore.swift`

- [ ] **Step 1: Run full automated verification**

Run:

```bash
swift test
swift build
```

Expected: all tests pass and build succeeds.

- [ ] **Step 2: Launch the app**

Run:

```bash
script/build_and_run.sh
```

Expected: the app launches, the menu bar item appears, and the floating pet appears if `showPetOnLaunch` is true.

- [ ] **Step 3: Manually verify floating window behavior**

Check:

```text
1. Pet window has no title bar or opaque background.
2. Pet window floats above ordinary app windows.
3. Pet can be dragged to a new screen position.
4. Pet remains clickable.
5. Hide Pet removes the pet window.
6. Show Pet restores the pet window.
7. Quit closes the pet and exits the process.
```

Expected: every item passes.

- [ ] **Step 4: Manually verify settings**

Open Settings from the menu bar and check:

```text
1. Size slider changes pet size.
2. Reminder interval accepts arbitrary minute values within 1...240.
3. Sleep delay accepts arbitrary minute values within 1...240.
4. Lower-distraction toggle reduces bubble visibility.
5. Notification toggle requests permission only when enabled.
```

Expected: every item passes.

- [ ] **Step 5: Manually verify persistence**

Run:

```bash
script/build_and_run.sh
```

Then:

```text
1. Move the pet.
2. Change size to 1.6.
3. Change reminder interval to 3 minutes.
4. Quit.
5. Relaunch with script/build_and_run.sh.
```

Expected: size, settings, and position persist after relaunch.

- [ ] **Step 6: Re-run build after manual verification**

Run:

```bash
swift build
```

Expected: build succeeds.

- [ ] **Step 7: Confirm clean worktree**

Run:

```bash
git status --short
```

Expected: no modified files.

---

## Spec Coverage Review

- Native macOS app: covered by Tasks 1 and 7.
- Transparent floating pet window: covered by Task 7.
- Draggable and resizable pet: covered by Tasks 6, 7, and 8.
- Persistent position and size: covered by Tasks 2, 7, and 8.
- Pixel Siamese visual direction with placeholder first: covered by Task 5.
- Idle, sleep, wake, petting, reminding states: covered by Task 3.
- Configurable reminder interval defaulting to 25 minutes: covered by Tasks 2, 4, and 6.
- Default pet-only reminder with optional notification: covered by Tasks 4, 6, and 7.
- Menu bar and settings surface: covered by Tasks 6 and 7.
- Lower-distraction mode: covered by Tasks 2, 5, and 6.
- Unit and manual verification: covered by Tasks 2 through 8.

No spec requirements are intentionally deferred except the out-of-scope items listed in the design document.

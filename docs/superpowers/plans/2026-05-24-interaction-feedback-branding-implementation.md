# Interaction Feedback and SlackerBuddy Branding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make pet feedback visible and rename/package the app as SlackerBuddy.

**Architecture:** Extend `PetStateMachine` with directional and wave states, keep animation frame selection in `SpriteAnimator`, and wire direction/auto movement in `AppRuntime` plus `PetWindowController`. Generate deterministic paw icon assets and update package metadata in `script/build_and_run.sh`.

**Tech Stack:** SwiftPM, SwiftUI/AppKit, UserNotifications, shell packaging script, custom `MacPetTestRunner`.

---

### Task 1: State And Sprite Feedback

**Files:**
- Modify: `Sources/MacPetCore/Models/PetState.swift`
- Modify: `Sources/MacPetCore/State/PetStateMachine.swift`
- Modify: `Sources/MacPetCore/Animation/SpriteAnimator.swift`
- Modify: `Sources/MacPetCore/Petdex/SpriteFrameMapping.swift`
- Test: `Tests/MacPetTestRunner/PetStateMachineTests.swift`
- Test: `Tests/MacPetTestRunner/SpriteAnimatorTests.swift`

- [ ] Add failing tests for `.dragged(.left)`, `.dragged(.right)`, `.reminderFired` entering wave feedback, and automatic running direction.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner` and verify the new tests fail.
- [ ] Add `PetMovementDirection`, directional run states, and a waving/reminding state.
- [ ] Map the new states to blink, wave, and running frames.
- [ ] Run the test runner and commit.

### Task 2: Runtime And Window Movement

**Files:**
- Modify: `Sources/MacPet/App/AppRuntime.swift`
- Modify: `Sources/MacPet/Windowing/PetWindowController.swift`
- Test: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] Add failing source tests that `onMoved` carries direction, `AppRuntime` handles directional drag, and automatic running calls a programmatic window move.
- [ ] Run the test runner and verify failures.
- [ ] Change `PetWindowController.onMoved` to `(PetMovementDirection) -> Void`.
- [ ] Compare previous and new frame origins to infer left/right movement.
- [ ] Add a programmatic movement helper for automatic running that does not save/emit user movement.
- [ ] Keep automatic action animations visible for multiple ticks before completing.
- [ ] Run the test runner and commit.

### Task 3: Notification Feedback

**Files:**
- Modify: `Sources/MacPet/App/AppRuntime.swift`
- Modify: `Sources/MacPet/Views/SettingsView.swift`
- Modify: `Sources/MacPetCore/Localization/LocalizedStrings.swift`
- Test: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`
- Test: `Tests/MacPetTestRunner/LocalizationTests.swift`

- [ ] Add failing tests for notification feedback states and localized copy.
- [ ] Run the test runner and verify failures.
- [ ] Add a runtime notification status enum with requesting/enabled/denied/failed.
- [ ] Update the settings toggle section to show status text.
- [ ] Treat `requestAuthorization() == false` as denied and switch the toggle back off.
- [ ] Run the test runner and commit.

### Task 4: SlackerBuddy Branding And Icons

**Files:**
- Modify: `script/build_and_run.sh`
- Modify: `Sources/MacPet/App/MacPetApp.swift`
- Modify: `Sources/MacPetCore/Services/NotificationClient.swift`
- Create: `Assets/SlackerBuddyAppIcon.png`
- Create: `Assets/SlackerBuddyMenuBarIcon.png`
- Create: `Assets/SlackerBuddy.icns`
- Test: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] Add failing source tests for SlackerBuddy metadata and icon copy behavior.
- [ ] Run the test runner and verify failures.
- [ ] Generate a rounded paw app icon and monochrome paw menu bar icon inspired by the two user images.
- [ ] Update menu title, app name, bundle ID, notification title, and packaged executable metadata.
- [ ] Copy the `.icns` into the `.app` bundle and set `CFBundleIconFile`.
- [ ] Run the test runner, build, verify launch, and commit.

### Task 5: Final Verification And Merge Readiness

**Files:**
- No source changes expected.

- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build -Xswiftc -warn-concurrency -Xswiftc -strict-concurrency=complete`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools git diff --check`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools ./script/build_and_run.sh --verify`.
- [ ] Report results and offer merge/PR/keep/discard options.

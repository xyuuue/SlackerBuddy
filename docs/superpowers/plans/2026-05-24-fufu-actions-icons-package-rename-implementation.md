# FuFu Actions, Icons, and SlackerBuddy Package Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align SlackerBuddy's animation, icons, and package naming with the approved FuFu/Petdex and SlackerBuddy assets.

**Architecture:** Keep `PetState` as the behavior model, but make `SpriteAnimator` emit FuFu-compatible frame names and `SpriteFrameMapping` own row selection. Rename SwiftPM products/targets/folders in one mechanical pass after behavior tests are green, then update active tests and scripts to the new paths.

**Tech Stack:** SwiftPM, SwiftUI/AppKit, WebP/PNG Petdex sprites, shell packaging script, Pillow/iconutil for icon asset preparation.

---

### Task 1: FuFu Sprite Contract

**Files:**
- Modify: `Sources/MacPetCore/Animation/SpriteAnimator.swift`
- Modify: `Sources/MacPetCore/Petdex/SpriteFrameMapping.swift`
- Modify: `Tests/MacPetTestRunner/SpriteAnimatorTests.swift`
- Modify: `Tests/MacPetTestRunner/PetdexCatalogTests.swift`

- [ ] Add failing tests that idle cycles through `idle-0...idle-5`, blink feedback uses idle-row frames, right-running states map to row 1, and left-running states map to row 2.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner` and verify failures.
- [ ] Update `SpriteAnimator` to remove invented `blink-*`, `running-left-*`, and `running-right-*` frame names for Petdex rendering.
- [ ] Update `SpriteFrameMapping` so right-running states use row 1 and left-running states use row 2.
- [ ] Run tests and commit.

### Task 2: User Icon Assets

**Files:**
- Replace: `Assets/SlackerBuddyAppIcon.png`
- Replace: `Assets/SlackerBuddyMenuBarIcon.png`
- Replace: `Assets/SlackerBuddy.icns`
- Modify: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] Add failing tests that compare repo icon bytes to `/Users/xyue/Pictures/SlackerBuddy App Icon.png` and `/Users/xyue/Pictures/SlackerBuddy Touch Bar Icon.png`.
- [ ] Run the test runner and verify failures.
- [ ] Copy the provided icon PNGs into `Assets/`.
- [ ] Regenerate `Assets/SlackerBuddy.icns` from `Assets/SlackerBuddyAppIcon.png`.
- [ ] Run tests and commit.

### Task 3: SwiftPM Project Rename

**Files:**
- Modify: `Package.swift`
- Move: `Sources/MacPet` to `Sources/SlackerBuddy`
- Move: `Sources/MacPetCore` to `Sources/SlackerBuddyCore`
- Move: `Tests/MacPetTestRunner` to `Tests/SlackerBuddyTestRunner`
- Modify: active imports and source-level test paths
- Modify: `script/build_and_run.sh`

- [ ] Add failing source tests that active package metadata no longer contains `MacPet`, active source window title uses `SlackerBuddy`, and `script/build_and_run.sh` builds product `SlackerBuddy`.
- [ ] Run the old test runner and verify failures.
- [ ] Rename SwiftPM package/products/targets and directories.
- [ ] Replace `import MacPetCore` with `import SlackerBuddyCore`.
- [ ] Update source-level tests to read `Sources/SlackerBuddy/...` paths.
- [ ] Update temporary test suite names from `MacPetTests` to `SlackerBuddyTests`.
- [ ] Update build script so `APP_NAME` and `BUILD_PRODUCT` are both `SlackerBuddy`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run SlackerBuddyTestRunner` and commit.

### Task 4: Final Verification

**Files:** no source changes expected.

- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run SlackerBuddyTestRunner`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build -Xswiftc -warn-concurrency -Xswiftc -strict-concurrency=complete`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools git diff --check`.
- [ ] Run `DEVELOPER_DIR=/Library/Developer/CommandLineTools ./script/build_and_run.sh --verify`.
- [ ] Report results and offer branch completion options.

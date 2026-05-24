# Localization And Petdex Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Chinese/English language selection, load selectable Petdex pets, and seed the app with a hatch-pet Siamese cat package.

**Architecture:** `MacPetCore` owns language resolution, localized copy, Petdex catalog scanning, persisted preference fields, and sprite row mapping. The macOS app layer binds those models into Settings and Pet rendering, falling back to the existing drawn cat whenever no valid sprite pet is selected. The hatch-pet package lives under `~/.codex/pets/siamese-cat/` and is loaded through the same catalog path as future pets.

**Tech Stack:** SwiftPM, Swift 5.9, SwiftUI, AppKit window controller, executable test runner `MacPetTestRunner`, hatch-pet scripts and imagegen workflow.

---

## File Structure

- Create `Sources/MacPetCore/Localization/AppLanguage.swift`: language enum and system-locale resolution.
- Create `Sources/MacPetCore/Localization/LocalizedStrings.swift`: local string table for Chinese/English copy.
- Create `Sources/MacPetCore/Petdex/PetAsset.swift`: built-in and Petdex pet model.
- Create `Sources/MacPetCore/Petdex/PetdexCatalog.swift`: scan `~/.codex/pets` and validate `pet.json` + sprite paths.
- Create `Sources/MacPetCore/Petdex/SpriteFrameMapping.swift`: map `PetState` to hatch-pet atlas rows.
- Modify `Sources/MacPetCore/Models/PetPreferences.swift`: persist language and selected pet id.
- Modify `Sources/MacPetCore/Stores/SettingsStore.swift`: load/update new preference fields.
- Create `Sources/MacPet/Animation/PetSpriteSheetView.swift`: render one frame from a Petdex atlas.
- Modify `Sources/MacPet/Views/BubbleView.swift`: receive localized text from caller.
- Modify `Sources/MacPet/Views/PetView.swift`: switch between placeholder and sprite-sheet rendering.
- Modify `Sources/MacPet/Views/SettingsView.swift`: language picker and pet picker.
- Modify `Sources/MacPet/App/AppRuntime.swift`: own/refresh `PetdexCatalog` and selected pet asset.
- Modify `Sources/MacPet/App/MacPetApp.swift`: localized menu/settings labels if currently hard-coded.
- Create tests under `Tests/MacPetTestRunner/LocalizationTests.swift` and `Tests/MacPetTestRunner/PetdexCatalogTests.swift`.
- Modify existing tests in `Tests/MacPetTestRunner/SettingsStoreTests.swift`, `Tests/MacPetTestRunner/SpriteAnimatorTests.swift`, and `Tests/MacPetTestRunner/main.swift`.

## Task 1: Core Language And Preference Model

**Files:**
- Create: `Sources/MacPetCore/Localization/AppLanguage.swift`
- Create: `Sources/MacPetCore/Localization/LocalizedStrings.swift`
- Modify: `Sources/MacPetCore/Models/PetPreferences.swift`
- Modify: `Sources/MacPetCore/Stores/SettingsStore.swift`
- Create: `Tests/MacPetTestRunner/LocalizationTests.swift`
- Modify: `Tests/MacPetTestRunner/SettingsStoreTests.swift`
- Modify: `Tests/MacPetTestRunner/main.swift`

- [ ] **Step 1: Write failing language and settings tests**

Add tests for language resolution, localized strings, and preference persistence:

```swift
let localizationTests: [TestCase] = [
    TestCase(name: "system language resolves Chinese preferred locale") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["zh-Hans-US", "en-US"])
        try expect(language == .chinese, "Expected Chinese locale to resolve to Chinese")
    },
    TestCase(name: "system language resolves English for non Chinese locale") {
        let language = AppLanguage.system.resolved(preferredLanguages: ["fr-FR", "en-US"])
        try expect(language == .english, "Expected non-Chinese locale to resolve to English")
    },
    TestCase(name: "localized strings switch settings labels") {
        let zh = LocalizedStrings(language: .chinese)
        let en = LocalizedStrings(language: .english)
        try expect(zh.text(.settingsTitle) == "设置", "Expected Chinese settings title")
        try expect(en.text(.settingsTitle) == "Settings", "Expected English settings title")
    },
    TestCase(name: "localized reminder bubble switches copy") {
        try expect(LocalizedStrings(language: .chinese).text(.restReminderBubble) == "休息一下吧", "Expected Chinese reminder copy")
        try expect(LocalizedStrings(language: .english).text(.restReminderBubble) == "Time for a break", "Expected English reminder copy")
    }
]
```

Extend `SettingsStoreTests.swift`:

```swift
store.updateLanguage(.chinese)
store.updateSelectedPetID("siamese-cat")
let reloadedStore = SettingsStore(defaults: defaults)
try expect(reloadedStore.preferences.language == .chinese, "Expected language to persist")
try expect(reloadedStore.preferences.selectedPetID == "siamese-cat", "Expected selected pet id to persist")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: compile failure for missing `AppLanguage`, `LocalizedStrings`, `updateLanguage`, or `updateSelectedPetID`.

- [ ] **Step 3: Implement minimal language model and persistence**

Create `AppLanguage.swift`:

```swift
public enum AppLanguage: String, CaseIterable, Sendable {
    case system
    case chinese = "zh-Hans"
    case english = "en"

    public func resolved(preferredLanguages: [String] = Locale.preferredLanguages) -> AppLanguage {
        switch self {
        case .chinese, .english:
            return self
        case .system:
            return preferredLanguages.contains { $0.lowercased().hasPrefix("zh") } ? .chinese : .english
        }
    }
}
```

Create `LocalizedStrings.swift` with `settingsTitle`, `languageLabel`, `petLabel`, `restReminderBubble`, and all settings labels currently shown in `SettingsView`.

Update `PetPreferences` to include:

```swift
public var language: AppLanguage
public var selectedPetID: String
```

Default `language` to `.system` and `selectedPetID` to `PetAsset.builtinID`.

Update `SettingsStore` to load strings from `UserDefaults`, sanitize unknown language codes to `.system`, and add:

```swift
public func updateLanguage(_ language: AppLanguage)
public func updateSelectedPetID(_ petID: String)
```

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all tests pass.

- [ ] **Step 5: Commit Task 1**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources/MacPetCore Tests/MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: add language preferences"
```

## Task 2: Petdex Catalog And Sprite Mapping

**Files:**
- Create: `Sources/MacPetCore/Petdex/PetAsset.swift`
- Create: `Sources/MacPetCore/Petdex/PetdexCatalog.swift`
- Create: `Sources/MacPetCore/Petdex/SpriteFrameMapping.swift`
- Create: `Tests/MacPetTestRunner/PetdexCatalogTests.swift`
- Modify: `Tests/MacPetTestRunner/SpriteAnimatorTests.swift`
- Modify: `Tests/MacPetTestRunner/main.swift`

- [ ] **Step 1: Write failing Petdex tests**

Create temp directories with valid and invalid Petdex packages:

```swift
let petdexCatalogTests: [TestCase] = [
    TestCase(name: "catalog includes builtin pet when directory is empty") {
        let root = try temporaryDirectory()
        let catalog = PetdexCatalog(rootDirectory: root)
        let pets = catalog.loadPets()
        try expect(pets.map(\\.id).contains(PetAsset.builtinID), "Expected builtin pet")
    },
    TestCase(name: "catalog loads valid pet package") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "siamese-cat", displayName: "Siamese Cat", createSprite: true)
        let pets = PetdexCatalog(rootDirectory: root).loadPets()
        try expect(pets.contains { $0.id == "siamese-cat" && $0.spriteSheetURL != nil }, "Expected valid Petdex pet")
    },
    TestCase(name: "catalog skips pet package with missing sprite") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "broken-cat", displayName: "Broken Cat", createSprite: false)
        let pets = PetdexCatalog(rootDirectory: root).loadPets()
        try expect(!pets.contains { $0.id == "broken-cat" }, "Expected missing sprite package to be skipped")
    },
    TestCase(name: "catalog sorts pets by display name after builtin") {
        let root = try temporaryDirectory()
        try writePetPackage(root: root, id: "z-cat", displayName: "Z Cat", createSprite: true)
        try writePetPackage(root: root, id: "a-cat", displayName: "A Cat", createSprite: true)
        let pets = PetdexCatalog(rootDirectory: root).loadPets()
        try expect(pets.map(\\.id).prefix(3) == [PetAsset.builtinID, "a-cat", "z-cat"], "Expected builtin first then sorted pets")
    },
    TestCase(name: "sprite mapping chooses expected atlas rows") {
        try expect(SpriteFrameMapping.row(for: .idle) == 0, "Expected idle row")
        try expect(SpriteFrameMapping.row(for: .reminding) == 6, "Expected reminder waiting row")
        try expect(SpriteFrameMapping.row(for: .petting) == 3, "Expected petting waving row")
        try expect(SpriteFrameMapping.row(for: .waking) == 4, "Expected waking jumping row")
    }
]
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: compile failure for missing `PetAsset`, `PetdexCatalog`, and `SpriteFrameMapping`.

- [ ] **Step 3: Implement catalog and mapping**

Implement `PetAsset`:

```swift
public struct PetAsset: Identifiable, Equatable, Sendable {
    public static let builtinID = "builtin.siamese-placeholder"
    public let id: String
    public let displayName: String
    public let description: String
    public let spriteSheetURL: URL?
    public var isBuiltin: Bool { id == Self.builtinID }
}
```

Implement `PetdexCatalog.loadPets()` to:

- Always include `PetAsset.builtin`.
- Read each direct child under root.
- Decode `pet.json` keys `id`, `displayName`, `description`, and `spritesheetPath`.
- Resolve sprite path relative to the pet directory.
- Include only packages with an existing sprite file.
- Sort non-built-in pets by localized display name.

Implement `SpriteFrameMapping.row(for:)` using the spec mapping.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all tests pass.

- [ ] **Step 5: Commit Task 2**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources/MacPetCore Tests/MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: load Petdex catalog"
```

## Task 3: macOS Settings And Sprite Rendering

**Files:**
- Create: `Sources/MacPet/Animation/PetSpriteSheetView.swift`
- Modify: `Sources/MacPet/App/AppRuntime.swift`
- Modify: `Sources/MacPet/App/MacPetApp.swift`
- Modify: `Sources/MacPet/Views/PetView.swift`
- Modify: `Sources/MacPet/Views/SettingsView.swift`
- Modify: `Sources/MacPet/Views/BubbleView.swift`
- Modify: `Tests/MacPetTestRunner/AppLifecycleSourceTests.swift`

- [ ] **Step 1: Write source-level failing test for lifecycle ownership**

Extend `AppLifecycleSourceTests.swift` to assert that `AppRuntime` owns a catalog, refresh method, and passes selected pet plus localized strings into views:

```swift
try expect(appRuntimeSource.contains("PetdexCatalog"), "Expected runtime to own PetdexCatalog")
try expect(appRuntimeSource.contains("refreshPetCatalog"), "Expected runtime to refresh Petdex pets")
try expect(appRuntimeSource.contains("selectedPetAsset"), "Expected runtime to resolve selected pet asset")
try expect(petViewSource.contains("PetSpriteSheetView"), "Expected PetView to render Petdex sprites")
try expect(settingsViewSource.contains("Picker(strings.text(.languageLabel)"), "Expected localized language picker")
try expect(settingsViewSource.contains("Picker(strings.text(.petLabel)"), "Expected localized pet picker")
```

- [ ] **Step 2: Run tests and verify RED**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: source-level test fails because runtime and views do not yet reference catalog/sprite/localized pickers.

- [ ] **Step 3: Implement app integration**

Implement `PetSpriteSheetView` with `Image(nsImage:)`, loading `NSImage(contentsOf:)`, cropping the atlas by row/column in `NSImage`/`CGImage`, and falling back to `PixelCatPlaceholderView` when load/crop fails.

Update `AppRuntime`:

```swift
private let petdexCatalog: PetdexCatalog
private(set) var availablePets: [PetAsset]
var selectedPetAsset: PetAsset
func refreshPetCatalog()
func updateSelectedPet(_ petID: String)
func updateLanguage(_ language: AppLanguage)
```

Update `PetView` to accept `strings: LocalizedStrings` and `petAsset: PetAsset`, use `strings.text(.restReminderBubble)` for reminder bubbles, and render `PetSpriteSheetView` when `petAsset.spriteSheetURL` exists.

Update `SettingsView` to accept `availablePets`, create `strings` from resolved preferences language, and add pickers for language and pet.

Update `MacPetApp` menu labels and settings title with localized strings from runtime settings.

- [ ] **Step 4: Run tests and verify GREEN**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: all tests pass.

- [ ] **Step 5: Commit Task 3**

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add Sources/MacPet Tests/MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "feat: connect settings to localized Petdex pets"
```

## Task 4: Hatch Siamese Cat Petdex Package

**Files:**
- External package target: `${CODEX_HOME:-$HOME/.codex}/pets/siamese-cat/pet.json`
- External package target: `${CODEX_HOME:-$HOME/.codex}/pets/siamese-cat/spritesheet.webp`
- Run artifacts under a temporary hatch-pet run directory.

- [ ] **Step 1: Prepare hatch-pet run**

Use the hatch-pet skill with:

```text
Pet name: Siamese Cat
Pet notes: pixel-art Siamese kitten, cream body, dark face ears paws and tail, blue eyes, compact whole-body desktop pet silhouette, friendly expression, inspired by the user's reference image.
Style preset: pixel
```

Run `prepare_pet_run.py`, inspect `imagegen-jobs.json`, and keep the hatch-pet visible checklist updated.

- [ ] **Step 2: Generate base and rows with imagegen**

Use `$imagegen` workers for base, `idle`, `running-right`, mirrored or generated `running-left`, `waving`, `jumping`, `failed`, `waiting`, `running`, and `review`. Copy selected outputs into decoded paths and mark each job complete only after the copied file exists.

- [ ] **Step 3: Compose, validate, QA, and package**

Run:

```bash
python "$SKILL_DIR/scripts/extract_strip_frames.py" --decoded-dir "$RUN_DIR/decoded" --output-dir "$RUN_DIR/frames" --states all --method auto
python "$SKILL_DIR/scripts/inspect_frames.py" --frames-root "$RUN_DIR/frames" --json-out "$RUN_DIR/qa/review.json" --require-components
python "$SKILL_DIR/scripts/compose_atlas.py" --frames-root "$RUN_DIR/frames" --output "$RUN_DIR/final/spritesheet.png" --webp-output "$RUN_DIR/final/spritesheet.webp"
python "$SKILL_DIR/scripts/validate_atlas.py" "$RUN_DIR/final/spritesheet.webp" --json-out "$RUN_DIR/final/validation.json"
python "$SKILL_DIR/scripts/make_contact_sheet.py" "$RUN_DIR/final/spritesheet.webp" --output "$RUN_DIR/qa/contact-sheet.png"
python "$SKILL_DIR/scripts/render_animation_previews.py" --frames-root "$RUN_DIR/frames" --output-dir "$RUN_DIR/qa/previews"
```

Package to `${CODEX_HOME:-$HOME/.codex}/pets/siamese-cat/` with `pet.json` and `spritesheet.webp`, then write `qa/run-summary.json`.

- [ ] **Step 4: Confirm app can see package**

Run:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
```

Expected: tests pass. Manual app verification should show "Siamese Cat" in the pet picker when the package exists.

## Task 5: Final Verification

**Files:**
- No planned source changes except fixes from verification.

- [ ] **Step 1: Run complete verification**

Run:

```bash
./script/build_and_run.sh --verify
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run MacPetTestRunner
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift build -Xswiftc -warn-concurrency -Xswiftc -strict-concurrency=complete
DEVELOPER_DIR=/Library/Developer/CommandLineTools git diff --check
```

Expected: every command exits 0.

- [ ] **Step 2: Manual launch smoke test**

Run:

```bash
./script/build_and_run.sh
```

Confirm the app launches, settings opens, language can switch between Chinese and English, pet picker includes the built-in pet and Siamese Cat when packaged, and the pet window still renders if the Petdex package is removed.

- [ ] **Step 3: Commit final fixes if any**

If verification required fixes:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools git add <changed-files>
DEVELOPER_DIR=/Library/Developer/CommandLineTools git commit -m "fix: stabilize localization and Petdex integration"
```

## Self-Review

- Spec coverage: language selection, bilingual strings, Petdex scanning, selected pet persistence, sprite mapping, hatch-pet Siamese package, fallback behavior, and verification are all covered.
- Placeholder scan: the word placeholder is used only for the existing built-in pet renderer and fallback identity.
- Type consistency: `AppLanguage`, `LocalizedStrings`, `PetAsset`, `PetdexCatalog`, `SpriteFrameMapping`, and `selectedPetID` names are consistent across tasks.

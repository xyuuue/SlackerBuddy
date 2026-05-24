# Localization And Petdex Design

## Goal

Add two user-facing capabilities to Mac Pet:

- A language selector with Chinese and English modes.
- Petdex-backed pet image selection, seeded with a hatch-pet Siamese cat package.

The app should keep working when no Petdex pet exists, when a selected pet is removed, or when the generated sprite package is invalid.

## User Experience

Settings gains a language picker with three practical outcomes:

- Chinese mode shows app menu labels, settings labels, reminder copy, and pet bubbles in Chinese.
- English mode shows the same surfaces in English.
- The first launch default follows the system language: Chinese for Chinese system locales, English otherwise.

Settings also gains a pet picker. The picker lists the built-in placeholder pet and any valid Petdex pets found under `~/.codex/pets/*/pet.json`. The selected pet persists. If the selected Petdex pet cannot be loaded, the app falls back to the built-in placeholder and keeps the settings UI usable.

The generated Siamese cat should be available as a Petdex pet so future pets can be added by dropping a `pet.json` and `spritesheet.webp` into `~/.codex/pets/<pet-id>/` without changing app code.

## Architecture

`MacPetCore` owns data models and pure loading logic:

- `AppLanguage` stores `.system`, `.chinese`, and `.english`. `.system` resolves to Chinese or English at runtime based on preferred locales.
- `LocalizedStrings` maps app string keys to Chinese and English copy without relying on Xcode `.strings` catalogs, keeping the SwiftPM app simple.
- `PetAsset` describes either the built-in placeholder or a Petdex pet.
- `PetdexCatalog` scans `~/.codex/pets`, decodes `pet.json`, validates the referenced sprite path, and returns sorted pets.

The app layer owns platform rendering:

- `SettingsView` renders language and pet selection controls.
- `PetView` switches between the existing placeholder renderer and a new sprite-sheet renderer when a valid Petdex sprite is selected.
- `AppRuntime` loads the catalog on startup and refreshes it when settings opens.

## Sprite Mapping

The Petdex atlas follows the hatch-pet contract: `1536x1872`, 8 columns by 9 rows, with `192x208` cells. Mac Pet consumes a subset of states:

- `idle` uses row 0.
- `reminding` uses row 6 (`waiting`) for a gentle attention pose.
- `petting` uses row 3 (`waving`) as a friendly interaction.
- `waking` uses row 4 (`jumping`) as the active wake-up pose.
- `sleeping` uses row 8 (`review`) only if a better sleeping row is unavailable; the built-in renderer remains the fallback for invalid sheets.

This mapping is intentionally centralized so a later version can add a native sleep row, richer animation semantics, or per-pet metadata without changing views.

## Persistence

`PetPreferences` adds:

- `languageCode`: `system`, `zh-Hans`, or `en`.
- `selectedPetID`: `builtin.siamese-placeholder` by default, or a Petdex pet id.

`SettingsStore` persists both fields with the existing `UserDefaults` suite. Invalid saved values are clamped back to safe defaults.

## Hatch-Pet Output

Use the `hatch-pet` workflow to create a Siamese cat pet package inspired by the user's reference image:

- Pixel-art Siamese kitten.
- Cream body, dark face/ears/paws/tail, blue eyes.
- Friendly, compact, readable at desktop-pet size.
- No text, shadows, detached effects, guide marks, or scenery.

The package target is:

```text
~/.codex/pets/siamese-cat/
  pet.json
  spritesheet.webp
```

The app should not depend on this specific pet. It should load any valid future Petdex package through the same catalog path.

## Testing

Add executable test-runner coverage for:

- Language default resolution and explicit Chinese/English modes.
- Localized copy lookup for key settings and bubble strings.
- Preference persistence for language and selected pet id.
- Petdex catalog scanning with valid pets, missing sprites, malformed JSON, and sorted display names.
- Sprite frame mapping from `PetState` to atlas rows.

Manual verification should include launching the app, opening settings, switching language, selecting the Siamese Petdex pet, and confirming the app still launches when the Petdex package is absent.

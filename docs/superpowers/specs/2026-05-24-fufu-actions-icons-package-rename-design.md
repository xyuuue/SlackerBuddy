# FuFu Actions, Icons, and SlackerBuddy Package Rename Design

## Goal

Fix the remaining feedback issues by matching FuFu's Petdex sprite contract, replacing the icon assets with the user-provided files, and renaming the SwiftPM project from MacPet/MacPetCore to SlackerBuddy/SlackerBuddyCore.

## Sources

- Petdex FuFu entry: idle row 0 has 6 frames with neutral breathing and blinking; run right is row 1; run left is row 2; waving is row 3; jumping is row 4; failed is row 5; waiting is row 6; running is row 7; review is row 8.
- Local pet package: `/Users/xyue/.codex/pets/fufu/pet.json` and `/Users/xyue/.codex/pets/fufu/spritesheet.webp`.
- User icon assets: `/Users/xyue/Pictures/SlackerBuddy App Icon.png` and `/Users/xyue/Pictures/SlackerBuddy Touch Bar Icon.png`.

## Decisions

- Idle and blink feedback must use FuFu's row 0 frames. The app should cycle `idle-0...idle-5`; it should not invent `blink-*` frame names for Petdex rendering.
- Directional running must use FuFu's rows: right = row 1, left = row 2.
- Waving stays row 3 and reminder waiting stays row 6.
- The menu/app icon assets in `Assets/` are replaced with the user-supplied images. The `.icns` is regenerated from the app icon image.
- SwiftPM package, products, targets, source folders, test folders, imports, and build script references are renamed to SlackerBuddy. Historical docs may keep old names as history; active source/tests/scripts should not.

## Validation

- Tests must fail before implementation for row/frame mismatch, icon source mismatch, and active project naming.
- Final verification runs `swift run SlackerBuddyTestRunner`, `swift build`, strict concurrency build, `git diff --check`, and `./script/build_and_run.sh --verify`.

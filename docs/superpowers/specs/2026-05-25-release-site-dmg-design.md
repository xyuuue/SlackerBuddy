# SlackerBuddy Release Site And DMG Design

## Goal

Create a static release page that introduces SlackerBuddy and FuFu, then provide a downloadable macOS DMG so other Apple computer users can install the app.

## Scope

- Add a static page at `docs/site/index.html`.
- Use local visual assets in `docs/site/assets/`.
- Link the primary download button to `docs/site/downloads/SlackerBuddy.dmg`.
- Generate the distributable DMG at both `dist/SlackerBuddy.dmg` and `docs/site/downloads/SlackerBuddy.dmg`.
- Keep notarization out of scope for this pass; the DMG is a local/shareable unsigned artifact.

## User Experience

The page opens directly with the product name, FuFu preview, and download button. Supporting sections introduce the pet behavior, reminders, customization, and installation steps.

## Packaging

The DMG contains `SlackerBuddy.app` and an `Applications` symlink. Users install by dragging the app into Applications. Because the artifact is not notarized, first launch may require macOS security approval.

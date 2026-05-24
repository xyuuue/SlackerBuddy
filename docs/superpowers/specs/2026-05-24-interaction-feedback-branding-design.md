# Interaction Feedback and SlackerBuddy Branding Design

## Goal

Make the pet feel responsive and alive, then rename the product from Mac Pet to SlackerBuddy with cat-paw app and menu bar icon assets based on the user-provided references.

## Approved Approach

Implement the A plan:

- Idle pets blink automatically when the mouse is not touching them.
- Dragging the pet left shows a left-running response; dragging right shows a right-running response.
- Reminder bubbles make the pet wave.
- Automatic actions visibly trigger periodic blink or run behavior.
- Automatic running moves the desktop pet left and right for a short distance when enabled.
- The system notification toggle gives visible feedback for requesting, enabled, denied, and failed states.
- The app name, bundle name, notification title, menu label, and packaged executable become SlackerBuddy.
- The app icon is a rounded cat paw icon inspired by image 1; the menu bar/toolbar icon is a monochrome paw inspired by image 2.

## Architecture

The state machine remains the source of truth for pet mood and transient animation states. Runtime owns timed behavior, reminder priority, notification permission requests, and automatic window movement. `PetWindowController` reports drag direction and exposes a narrow programmatic move API for automatic running without treating those moves as user drags.

Visual assets are generated into repository assets as deterministic PNG/icon files. The packaging script copies the icon into the `.app` bundle and uses the SlackerBuddy executable/bundle metadata.

## Testing

Add tests before implementation:

- State machine transitions for drag-left, drag-right, wave-on-reminder, and automatic running.
- Sprite animator maps new states to visible frames.
- Source-level wiring checks for directional movement, auto-run window movement, notification feedback, and SlackerBuddy packaging/icon metadata.
- Existing reminder, Petdex, settings, and packaging tests must continue to pass.

# Mac Pet Design

Date: 2026-05-23

## Goal

Build a native macOS desktop pet app centered on a pixel-art Siamese cat. The pet should quietly accompany the user during work, support light direct interaction, and provide gentle rest reminders with a user-configurable interval.

## Product Scope

The first version is a lightweight companion, not a full virtual pet game. The pet appears as a small always-on-top desktop cat that the user can drag anywhere on screen and resize. Position and size persist across launches.

The pet personality is quiet companionship with gentle focus coaching. During normal work it mostly idles, blinks, breathes, and lightly moves its tail. If the user does not interact with it for a configured period, it falls asleep. Clicking, petting, dragging, or opening its context controls wakes it up.

The rest reminder interval defaults to 25 minutes, but the user can set any desired number of minutes. When the timer fires, the cat performs a reminder animation and shows a small speech bubble. macOS system notifications are off by default and can be enabled in settings.

Out of scope for the first version:

- Feeding, growth, affection points, and complex pet-care mechanics.
- Screen, keyboard, or active-app monitoring.
- Complex movement around the screen.
- Multiple pets or skin management.

The architecture should still leave room for later medium-interaction features such as turning toward the cursor, taking a few steps, and richer speech bubbles.

## Visual Direction

The pet should be a redrawn pixel sprite set that closely matches the provided Siamese cat reference:

- Large bright blue eyes.
- Cream body.
- Dark Siamese mask, ears, legs, paws, and striped tail.
- Black or dark purple pixel outline.
- Chibi proportions with a large head, compact body, short legs, and friendly smile.

The reference image should not be treated as a single static crop for the app. Instead, create a sprite set that preserves the look while allowing natural animation. Sprites should use a consistent canvas size, such as 128x128 or 192x192, and render with nearest-neighbor scaling so resizing remains crisp.

Initial animation sets:

- `idle`
- `blink`
- `tail_sway`
- `sleep`
- `wake`
- `petting`
- `reminder`

The first development pass may use temporary placeholder sprites to validate behavior, then replace them with polished pixel art.

## macOS Experience

The app has two visible surfaces:

- A transparent floating pet window.
- A menu bar entry and standard settings window.

The floating pet window contains only the cat sprite and optional speech bubble. It should have no normal title bar, no opaque background, and no visible window chrome. It should remain above normal app windows but avoid stealing focus unnecessarily.

Users can:

- Drag the pet to reposition it.
- Resize the pet.
- Temporarily hide or restore the pet.
- Enable a lower-distraction mode.
- Open settings from the menu bar or context controls.
- Quit from the menu bar.

The app should restore the last pet position, size, visibility preference, and reminder settings when relaunched.

## Technical Architecture

Use SwiftUI for application state, views, settings, and animation presentation. Use a small AppKit bridge only for macOS window behavior that SwiftUI does not model cleanly.

Core components:

- `MacPetApp`: app entry point, scene setup, menu bar entry, and settings scene.
- `PetWindowController`: creates and manages the transparent, borderless, always-on-top floating window.
- `PetView`: renders the current sprite animation and handles direct pet interaction.
- `BubbleView`: renders short reminder or reaction messages.
- `SettingsView`: exposes reminder interval, notification preference, sleep timing, pet size, launch behavior, and lower-distraction mode.
- `PetState`: defines the pet state model.
- `PetStateMachine`: owns state transitions such as idle, sleep, wake, petting, and reminding.
- `SpriteAnimator`: maps pet state to sprite frame sequences and frame timing.
- `ReminderScheduler`: handles the configurable rest reminder interval and reset behavior.
- `SettingsStore`: persists user preferences with `UserDefaults`, `@AppStorage`, or a narrow observable store.

Suggested project layout:

```text
App/MacPetApp.swift
Windowing/PetWindowController.swift
Views/PetView.swift
Views/BubbleView.swift
Views/SettingsView.swift
Models/PetState.swift
Stores/SettingsStore.swift
Services/ReminderScheduler.swift
Animation/SpriteAnimator.swift
Assets/PetSprites/
```

SwiftUI remains the source of truth for user preferences and pet state. AppKit should own only the imperative window behavior, with a narrow interface back to SwiftUI.

## State Machine

First-version pet states:

- `idle`: normal resting state.
- `blink`: short ambient blink layered into idle behavior.
- `sleeping`: entered after no direct pet interaction for the configured sleep delay.
- `waking`: short transition after the user interacts with a sleeping pet.
- `petting`: short positive reaction after clicking or petting.
- `reminding`: rest reminder state with animation and optional bubble.

State behavior:

- The pet starts in `idle`.
- Ambient blink and tail-sway animation can occur while idle.
- After the configured inactivity duration, the pet enters `sleeping`.
- Clicking, dragging, or opening pet controls wakes it.
- Clicking the pet while awake triggers `petting`, then returns to `idle`.
- When the reminder interval elapses, the pet enters `reminding`.
- Clicking the pet or reminder bubble dismisses the reminder and restarts the timer.

Lower-distraction mode reduces ambient animation frequency and suppresses proactive bubbles except for subtle reminder behavior.

## Reminder Behavior

The reminder interval is user-configurable and defaults to 25 minutes. The settings UI should provide convenient presets and allow manual minute entry.

Default reminder behavior:

- No system notification.
- Pet performs a reminder animation.
- Pet shows a short bubble, such as "休息一下吧".
- User dismisses by clicking the pet or bubble.
- Timer restarts after dismissal.

Optional notification behavior:

- If enabled, the app also sends a macOS notification when the reminder fires.
- Notification permission should be requested only when the user enables this setting.

The app should not monitor typing, app usage, webcam, microphone, or screen contents in the first version.

## Settings

First-version settings:

- Pet size or scale.
- Reminder interval in minutes.
- System notification toggle.
- Automatic sleep delay.
- Show pet on launch.
- Lower-distraction mode.
- Reset pet position.

Settings should use native macOS controls and a standard settings scene. Values should persist immediately.

## Verification Plan

Unit tests:

- `PetStateMachine` transitions from idle to sleeping after inactivity.
- User interaction wakes the pet and resets inactivity.
- Petting returns to idle after the reaction duration.
- `ReminderScheduler` respects custom intervals.
- Reminder dismissal restarts the timer.
- Lower-distraction mode suppresses nonessential bubbles.

Manual verification:

- Floating pet window is transparent, borderless, and above normal windows.
- Pet can be dragged and resized.
- Position and size persist after relaunch.
- Pet can be hidden and restored.
- Reminder interval can be changed to arbitrary minute values.
- Reminder bubble appears without a system notification by default.
- Enabling notifications requests permission and sends a notification.
- Pixel sprites remain crisp at supported sizes.
- Speech bubble does not block normal pet dragging or obscure the pet awkwardly.

## Open Implementation Notes

- Use placeholder sprites while building behavior, then replace with polished pixel art.
- Keep the AppKit bridge narrow and testable by isolating it in `PetWindowController`.
- Avoid adding screen or keyboard monitoring until a later design explicitly covers privacy, permissions, and user value.

# Reminders And Autonomy Design

## Goal

Add richer workday companion behavior to Mac Pet:

- Adjustable bubble display duration.
- Autonomous pet actions, including optional automatic running animation.
- Rest reminders that can be enabled or disabled.
- Optional enlarged rest blocking overlay.
- Water reminders with a separate enable switch and custom interval.

The feature should keep the pet helpful without making it noisy. Every new behavior must have a setting, safe defaults, and a clear fallback when disabled.

## User Experience

Settings gains a reminder-focused section modeled after the supplied screenshot:

- `开启休息提醒` / `Enable rest reminders`
- `休息间隔` / `Rest interval`
- `休息时放大挡屏` / `Enlarge pet during rest`
- `挡屏时长` / `Blocking duration`
- `挡屏比例` / `Blocking scale`
- `开启喝水提醒` / `Enable water reminders`
- `喝水间隔` / `Water interval`

Settings also gains behavior controls:

- `气泡显示时长` / `Bubble duration`
- `开启自动动作` / `Enable automatic actions`
- `动作频率` / `Action frequency`
- `开启自动跑动` / `Enable automatic running`

Intervals are edited in minutes. Bubble and blocking duration are edited in seconds. Blocking scale is edited as a percentage of the main display's shorter side. Values are clamped to practical ranges so invalid stored values cannot make the UI unusable.

## Defaults

- Rest reminders: enabled.
- Rest interval: 45 minutes.
- Enlarge pet during rest: enabled.
- Blocking duration: 15 seconds.
- Blocking scale: 40%.
- Water reminders: enabled.
- Water interval: 90 minutes.
- Bubble display duration: 6 seconds.
- Automatic actions: enabled.
- Action frequency: 8 minutes.
- Automatic running: disabled.

Lower-distraction mode remains stronger than automatic animation: when lower-distraction mode is enabled, automatic actions are less frequent and automatic running is suppressed.

## Reminder Behavior

Rest and water reminders are separate schedules. Disabling one reminder stops its schedule and clears its active state without affecting the other.

When a rest reminder fires:

- The pet enters the reminder state.
- The bubble shows localized rest reminder copy.
- If system notifications are enabled, the app sends the existing rest notification.
- If enlarged rest blocking is enabled, the app temporarily enlarges the pet in a centered overlay for the configured blocking duration.
- Clicking the pet, dismissing the bubble, or the blocking duration ending clears the active rest reminder and schedules the next rest reminder.

When a water reminder fires:

- The pet enters the reminder state.
- The bubble shows localized water reminder copy.
- No blocking overlay appears.
- Clicking the pet or dismissing the bubble clears the active water reminder and schedules the next water reminder.

If rest and water reminders become due at the same time, rest reminder takes priority. Water reminder remains pending and can fire after the rest reminder is dismissed.

## Bubble Behavior

Reminder bubbles auto-hide after the configured bubble duration. Auto-hiding a bubble does not necessarily dismiss the underlying reminder if the reminder is still active; it only reduces visual noise. Pet click or explicit dismiss still clears the reminder.

Transient automatic-action bubbles, if added later, use the same duration. This iteration only needs rest and water bubbles.

## Automatic Actions

Automatic actions are lightweight state changes triggered by an autonomous action scheduler:

- Blink or small idle gesture when automatic actions are enabled.
- Optional running animation when automatic running is enabled and lower-distraction mode is off.

Automatic actions must not interrupt an active reminder, sleeping state, waking animation, petting animation, or blocking overlay. They also must not reset the user's inactivity timer unless the user interacts with the pet.

## Blocking Overlay

The blocking overlay is an AppKit-managed temporary pet window mode rather than a new full-screen app scene. It should:

- Center the pet on the main display.
- Scale the pet to the configured blocking percentage.
- Stay click-through behavior consistent with the existing pet unless interaction is needed to dismiss the reminder.
- Automatically restore the previous pet position and scale when the configured blocking duration ends or the reminder is dismissed.

The overlay should not persist size or position as the user's normal pet placement.

## Architecture

`MacPetCore` owns pure behavior:

- `PetPreferences` stores all new settings and clamps ranges.
- `SettingsStore` loads, updates, and persists each setting.
- A reusable scheduler type handles rest, water, and automatic action timers.
- `PetStateMachine` gains events for water reminders and automatic actions.
- Localized strings include all new settings labels and water reminder copy.

The app layer owns platform behavior:

- `AppRuntime` owns rest, water, and automatic action schedulers.
- `PetWindowController` gains temporary blocking presentation APIs that do not overwrite persisted normal placement.
- `SettingsView` renders the new controls with localized labels.
- `PetView` observes active bubble copy and auto-hides bubbles after the configured duration.

## Testing

Add executable test-runner coverage for:

- Preference defaults and clamping for new values.
- Persistence of every new setting.
- Rest scheduler disable/enable behavior.
- Water scheduler interval behavior.
- Rest priority when rest and water fire together.
- Bubble auto-hide timing.
- Automatic actions do not fire during active reminders or when disabled.
- Lower-distraction mode suppresses automatic running.
- Source-level tests that the blocking overlay does not persist normal pet placement.
- Source-level tests that settings labels are localized and no new user-facing English leaks into Chinese mode.

Manual verification should include opening settings, changing each new control, confirming rest and water reminders can be disabled independently, confirming the enlarged rest overlay restores the normal pet size/position, and confirming automatic running does not happen in lower-distraction mode.

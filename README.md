# SlackerBuddy

SlackerBuddy is a native macOS desktop pet app. FuFu, the default Siamese cat, keeps you company while you work, reacts to clicks and drags, and reminds you to rest or drink water.

Website: [https://slackerbuddy.vercel.app](https://slackerbuddy.vercel.app)

Author: Yueling Qiu  
Contact: [lindaqiuyueling@gmail.com](mailto:lindaqiuyueling@gmail.com)

## Features

- Native SwiftUI and AppKit macOS companion window
- Draggable and resizable desktop pet
- FuFu sprite animations for idle, blinking, waving, jumping, waiting, running, and reminder states
- Customizable rest reminder interval
- Optional enlarged rest-blocking mode that stays within the visible screen area
- Bubble button for ending rest blocking early with "I'm back!" / "我回来啦！"
- Customizable water reminders
- Automatic actions and optional automatic running
- Lower-distraction mode
- Chinese and English app settings
- PetDex support for installing and selecting custom pets
- Static download website with English default and Chinese language toggle

## Download

Download the latest DMG from the website:

[Download SlackerBuddy](https://slackerbuddy.vercel.app/downloads/SlackerBuddy.dmg)

This project currently ships as a lightweight ad-hoc signed build. On first launch, macOS may require you to right-click or Control-click `SlackerBuddy.app`, choose **Open**, then approve it in **Privacy & Security** with **Open Anyway**.

## PetDex Pets

SlackerBuddy supports PetDex pet packages. To add a pet:

1. Visit [PetDex](https://petdex.crafter.run/).
2. Download a pet package you like.
3. Place the pet folder in `~/.codex/pets`.
4. Open SlackerBuddy settings from the menu bar.
5. Pick the new pet from the **Pet** selector.

A PetDex pet folder usually contains a `pet.json` file and a spritesheet image.

## Build Locally

Requirements:

- macOS 14 or later
- Xcode Command Line Tools
- Swift 5.9 or later

Run the app:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools ./script/build_and_run.sh
```

Verify the app bundle launches:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools ./script/build_and_run.sh --verify
```

Run tests:

```bash
DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run SlackerBuddyTestRunner
```

## Repository Layout

- `Sources/SlackerBuddy` - macOS app, windows, SwiftUI views, and AppKit integration
- `Sources/SlackerBuddyCore` - state machines, settings, scheduling, localization, and PetDex loading
- `Tests/SlackerBuddyTestRunner` - lightweight custom test runner
- `Assets` - app icon and menu bar icon assets
- `docs/site` - static website and downloadable DMG
- `script/build_and_run.sh` - local build, bundle, signing, and launch helper

## License

SlackerBuddy is proprietary software by Yueling Qiu. All rights reserved. See [LICENSE](LICENSE).

For questions, help, or collaboration, contact Yueling Qiu at [lindaqiuyueling@gmail.com](mailto:lindaqiuyueling@gmail.com).

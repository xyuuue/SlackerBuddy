# SlackerBuddy for Windows

This folder contains the Windows version of SlackerBuddy as a separate Electron app. It preserves the SlackerBuddy name, the existing paw icon assets, the FuFu spritesheet, PetDex loading, bilingual settings, reminders, automatic actions, automatic running, drag feedback, system notifications, and rest-blocking behavior.

## Requirements

- Windows 10 or later for normal use
- Node.js 20 or later for development
- npm

## Run Locally

```powershell
cd Windows
npm install
npm start
```

## Build Windows Installer

```powershell
cd Windows
npm install
npm run dist
```

The Windows installer and portable build are written to `Windows/dist`.

## PetDex Pets

The Windows app loads PetDex pets from:

```text
%USERPROFILE%\.codex\pets
```

Each pet folder should contain `pet.json` and its spritesheet image, matching the macOS SlackerBuddy PetDex format.

## Icons

The Windows app uses the existing SlackerBuddy icon artwork copied from the repository:

- `Windows/assets/SlackerBuddyAppIcon.png`
- `Windows/assets/SlackerBuddyTrayIcon.png`
- `Windows/assets/SlackerBuddy.ico`

The `.ico` file is only a Windows packaging conversion of the existing app icon.

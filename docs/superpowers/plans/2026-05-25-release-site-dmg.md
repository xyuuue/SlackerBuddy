# SlackerBuddy Release Site And DMG Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a static SlackerBuddy release page and produce a downloadable DMG installer artifact.

**Architecture:** The release page is a static HTML file under `docs/site/` with copied image assets. The DMG is generated from the existing `dist/SlackerBuddy.app` bundle and mirrored into `docs/site/downloads/` so the page link works locally and when hosted.

**Tech Stack:** HTML/CSS, SwiftPM app bundle script, macOS `hdiutil`, existing custom Swift test runner.

---

### Task 1: Release Page

**Files:**
- Create: `docs/site/index.html`
- Create: `docs/site/assets/slackerbuddy-app-icon.png`
- Create: `docs/site/assets/slackerbuddy-menu-icon.png`
- Create: `docs/site/assets/fufu-idle.png`
- Modify: `Tests/SlackerBuddyTestRunner/AppLifecycleSourceTests.swift`

- [x] **Step 1: Add a failing source test**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run SlackerBuddyTestRunner`

Expected: fails because `docs/site/index.html` does not exist.

- [x] **Step 2: Generate visual assets**

Copy the SlackerBuddy app/menu icons and extract the first FuFu idle frame from `/Users/xyue/.codex/pets/fufu/spritesheet.webp`.

- [x] **Step 3: Write the static page**

Create `docs/site/index.html` with a hero, FuFu preview, feature summary, installation steps, and download link to `downloads/SlackerBuddy.dmg`.

- [x] **Step 4: Verify the page test**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools swift run SlackerBuddyTestRunner`

Expected: 0 failures.

### Task 2: DMG Artifact

**Files:**
- Create: `dist/SlackerBuddy.dmg`
- Create: `docs/site/downloads/SlackerBuddy.dmg`

- [x] **Step 1: Build the app bundle**

Run: `DEVELOPER_DIR=/Library/Developer/CommandLineTools ./script/build_and_run.sh --verify`

Expected: `dist/SlackerBuddy.app` exists and launches.

- [x] **Step 2: Build the DMG**

Create a temporary staging folder containing `SlackerBuddy.app` and an `Applications` symlink, then run `hdiutil create -format UDZO`.

- [x] **Step 3: Mirror the DMG into the site download folder**

Copy `dist/SlackerBuddy.dmg` to `docs/site/downloads/SlackerBuddy.dmg`.

- [x] **Step 4: Inspect the DMG**

Run: `hdiutil imageinfo dist/SlackerBuddy.dmg`.

Expected: image format is `UDZO`.

const { app, BrowserWindow, ipcMain, Menu, Notification, Tray, screen, nativeImage } = require("electron");
const path = require("path");
const fs = require("fs");
const Store = require("electron-store");

const isWindows = process.platform === "win32";
const store = new Store({ name: "slackerbuddy-settings" });

let petWindow;
let settingsWindow;
let tray;

function assetPath(...parts) {
  if (app.isPackaged) {
    return path.join(process.resourcesPath, "assets", ...parts);
  }

  return path.join(__dirname, "..", "assets", ...parts);
}

const defaultPreferences = {
  language: "system",
  selectedPetID: "fufu",
  petScale: 1,
  showPetOnLaunch: true,
  lowerDistractionMode: false,
  restRemindersEnabled: true,
  reminderIntervalMinutes: 45,
  restBlockingEnabled: true,
  restBlockingDurationSeconds: 15,
  restBlockingScalePercent: 40,
  waterRemindersEnabled: true,
  waterIntervalMinutes: 90,
  bubbleDurationSeconds: 6,
  automaticActionsEnabled: true,
  automaticActionIntervalMinutes: 8,
  automaticRunningEnabled: false,
  automaticRunDirectionMode: "random",
  systemNotificationsEnabled: false
};

function preferences() {
  return normalizePreferences({ ...defaultPreferences, ...(store.get("preferences") || {}) });
}

function normalizePreferences(pref) {
  const selectedPetID = pref.selectedPetID === "builtin.siamese-placeholder" ? "fufu" : (pref.selectedPetID || "fufu");
  return {
    ...pref,
    selectedPetID,
    showPetOnLaunch: pref.showPetOnLaunch !== false
  };
}

function savePreferences(nextPreferences) {
  const merged = { ...preferences(), ...nextPreferences };
  store.set("preferences", merged);
  if (petWindow && !petWindow.isDestroyed()) {
    petWindow.webContents.send("preferences-updated", merged);
  }
  rebuildTrayMenu();
  return merged;
}

function createPetWindow() {
  petWindow = new BrowserWindow({
    width: 220,
    height: 220,
    frame: false,
    transparent: true,
    resizable: false,
    skipTaskbar: true,
    alwaysOnTop: true,
    hasShadow: false,
    show: false,
    icon: assetPath("SlackerBuddy.ico"),
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  petWindow.setMenuBarVisibility(false);
  petWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  petWindow.loadFile(path.join(__dirname, "renderer.html"), { query: { window: "pet" } });
  petWindow.once("ready-to-show", () => {
    const pref = preferences();
    restorePetBounds(pref);
    if (pref.showPetOnLaunch) {
      petWindow.showInactive();
    }
  });
  petWindow.webContents.once("did-finish-load", () => {
    const pref = preferences();
    restorePetBounds(pref);
    if (pref.showPetOnLaunch) {
      petWindow.showInactive();
    }
  });
}

function createSettingsWindow() {
  if (settingsWindow && !settingsWindow.isDestroyed()) {
    settingsWindow.show();
    settingsWindow.focus();
    return;
  }

  settingsWindow = new BrowserWindow({
    width: 520,
    height: 720,
    minWidth: 440,
    minHeight: 560,
    title: "SlackerBuddy Settings",
    icon: assetPath("SlackerBuddy.ico"),
    show: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false
    }
  });

  settingsWindow.setMenuBarVisibility(false);
  settingsWindow.loadFile(path.join(__dirname, "renderer.html"), { query: { window: "settings" } });
  settingsWindow.once("ready-to-show", () => {
    settingsWindow.show();
    settingsWindow.focus();
  });
  settingsWindow.on("closed", () => {
    settingsWindow = null;
  });
}

function restorePetBounds(pref) {
  const savedBounds = store.get("petBounds");
  if (savedBounds) {
    petWindow.setBounds(savedBounds);
    return;
  }

  const display = screen.getPrimaryDisplay().workArea;
  const size = petWindowSize(pref.petScale);
  petWindow.setBounds({
    x: Math.round(display.x + display.width - size.width - 40),
    y: Math.round(display.y + display.height - size.height - 40),
    width: size.width,
    height: size.height
  });
}

function petWindowSize(scale) {
  const clamped = Math.min(Math.max(Number(scale) || 1, 0.5), 3);
  const side = Math.round(220 * clamped);
  return { width: side, height: side };
}

function setPetBounds(bounds) {
  if (!petWindow || petWindow.isDestroyed()) return;
  const display = screen.getDisplayMatching(bounds).workArea;
  const width = Math.max(120, Math.round(bounds.width));
  const height = Math.max(120, Math.round(bounds.height));
  const x = Math.min(Math.max(Math.round(bounds.x), display.x), display.x + display.width - width);
  const y = Math.min(Math.max(Math.round(bounds.y), display.y), display.y + display.height - height);
  const next = { x, y, width, height };
  petWindow.setBounds(next);
  store.set("petBounds", next);
}

function createTray() {
  const trayImage = nativeImage.createFromPath(assetPath(isWindows ? "SlackerBuddy.ico" : "SlackerBuddyTrayIcon.png"));
  tray = new Tray(trayImage);
  tray.setToolTip("SlackerBuddy");
  rebuildTrayMenu();
  tray.on("double-click", () => {
    showPet();
  });
}

function rebuildTrayMenu() {
  const pref = preferences();
  const template = [
    { label: "Show Pet", click: showPet },
    { label: "Hide Pet", click: hidePet },
    { label: "Settings", click: createSettingsWindow },
    { type: "separator" },
    {
      label: "Lower-distraction mode",
      type: "checkbox",
      checked: pref.lowerDistractionMode,
      click: (item) => savePreferences({ lowerDistractionMode: item.checked })
    },
    {
      label: "System notifications",
      type: "checkbox",
      checked: pref.systemNotificationsEnabled,
      click: (item) => savePreferences({ systemNotificationsEnabled: item.checked })
    },
    { type: "separator" },
    { label: "Quit SlackerBuddy", click: () => app.quit() }
  ];
  tray.setContextMenu(Menu.buildFromTemplate(template));
}

function showPet() {
  if (!petWindow || petWindow.isDestroyed()) createPetWindow();
  restorePetBounds(preferences());
  petWindow.showInactive();
}

function hidePet() {
  if (petWindow && !petWindow.isDestroyed()) petWindow.hide();
}

function petdexRoot() {
  return path.join(app.getPath("home"), ".codex", "pets");
}

function bundledPet() {
  return {
    id: "fufu",
    displayName: "FuFu (Built-in)",
    description: "Built-in pixel-art Siamese kitten desktop pet with cream fur, dark points, blue eyes, and friendly compact proportions.",
    spritesheetPath: assetPath("fufu-spritesheet.webp"),
    bundled: true
  };
}

function loadPetdexPets() {
  const builtInPet = bundledPet();
  const pets = [builtInPet];
  const root = petdexRoot();
  if (!fs.existsSync(root)) return pets;

  for (const folderName of fs.readdirSync(root)) {
    const folder = path.join(root, folderName);
    const metadataPath = path.join(folder, "pet.json");
    if (!fs.statSync(folder).isDirectory() || !fs.existsSync(metadataPath)) continue;
    try {
      const metadata = JSON.parse(fs.readFileSync(metadataPath, "utf8"));
      const spritesheetPath = path.join(folder, metadata.spritesheetPath || "");
      if (!metadata.id || !fs.existsSync(spritesheetPath)) continue;
      if (metadata.id === builtInPet.id) continue;
      pets.push({
        id: metadata.id,
        displayName: metadata.displayName || metadata.id,
        description: metadata.description || "",
        spritesheetPath,
        bundled: false
      });
    } catch {
      continue;
    }
  }

  return pets.sort((left, right) => {
    if (left.id === "fufu") return -1;
    if (right.id === "fufu") return 1;
    return left.displayName.localeCompare(right.displayName);
  });
}

function sendNotification(title, body) {
  const pref = preferences();
  if (!pref.systemNotificationsEnabled || !Notification.isSupported()) return;
  new Notification({
    title,
    body,
    icon: assetPath("SlackerBuddyAppIcon.png")
  }).show();
}

function registerIpc() {
  ipcMain.handle("app:get-initial-state", () => ({
    preferences: preferences(),
    pets: loadPetdexPets(),
    petdexRoot: petdexRoot(),
    assets: {
      appIcon: assetPath("SlackerBuddyAppIcon.png"),
      trayIcon: assetPath("SlackerBuddyTrayIcon.png"),
      fufuIdle: assetPath("fufu-idle.png")
    }
  }));

  ipcMain.handle("settings:save", (_event, nextPreferences) => savePreferences(nextPreferences));
  ipcMain.handle("petdex:refresh", () => loadPetdexPets());
  ipcMain.handle("pet:get-bounds", () => petWindow?.getBounds());
  ipcMain.handle("pet:set-bounds", (_event, bounds) => setPetBounds(bounds));
  ipcMain.handle("pet:resize", (_event, scale) => {
    const bounds = petWindow.getBounds();
    const size = petWindowSize(scale);
    setPetBounds({ ...bounds, width: size.width, height: size.height });
  });
  ipcMain.handle("pet:blocking-bounds", (_event, scalePercent) => {
    const display = screen.getDisplayNearestPoint(screen.getCursorScreenPoint()).workArea;
    const ratio = Math.min(Math.max(Number(scalePercent) || 40, 10), 90) / 100;
    const size = Math.round(Math.min(display.width, display.height) * ratio);
    const bounds = {
      x: Math.round(display.x + (display.width - size) / 2),
      y: Math.round(display.y + (display.height - size) / 2),
      width: size,
      height: size
    };
    setPetBounds(bounds);
    return bounds;
  });
  ipcMain.handle("screen:get-cursor-point", () => screen.getCursorScreenPoint());
  ipcMain.handle("notify", (_event, payload) => sendNotification(payload.title, payload.body));
  ipcMain.on("pet:ready", () => showPet());
  ipcMain.on("settings:open", createSettingsWindow);
  ipcMain.on("pet:show", showPet);
  ipcMain.on("pet:hide", hidePet);
}

app.whenReady().then(() => {
  app.setName("SlackerBuddy");
  registerIpc();
  createPetWindow();
  createTray();
});

app.on("window-all-closed", (event) => {
  event.preventDefault();
});

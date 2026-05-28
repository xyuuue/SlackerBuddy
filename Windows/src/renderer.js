const params = new URLSearchParams(window.location.search);
const windowKind = params.get("window") || "pet";
const api = window.slackerBuddy;

const frameRows = {
  idle: 0,
  blink: 0,
  sleeping: 8,
  waking: 4,
  petting: 3,
  reminding: 6,
  waving: 6,
  reviewing: 8,
  jumping: 4,
  failed: 5,
  waiting: 6,
  running: 7,
  dragRunningRight: 1,
  dragRunningLeft: 2,
  automaticRunningRight: 1,
  automaticRunningLeft: 2,
  automaticBlink: 0
};

const stateFrames = {
  idle: [0, 1, 2, 3, 4, 5],
  blink: [4, 5],
  automaticBlink: [4, 5],
  sleeping: [0, 1],
  waking: [0, 1, 2, 3, 4],
  petting: [0, 1, 2, 3],
  reminding: [0, 1, 2, 3, 4, 5],
  waving: [0, 1, 2, 3],
  reviewing: [0, 1, 2, 3, 4, 5],
  jumping: [0, 1, 2, 3, 4],
  failed: [0, 1, 2, 3, 4, 5, 6, 7],
  waiting: [0, 1, 2, 3, 4, 5],
  running: [0, 1, 2, 3, 4, 5],
  dragRunningRight: [0, 1, 2, 3, 4, 5, 6, 7],
  dragRunningLeft: [0, 1, 2, 3, 4, 5, 6, 7],
  automaticRunningRight: [0, 1, 2, 3, 4, 5, 6, 7],
  automaticRunningLeft: [0, 1, 2, 3, 4, 5, 6, 7]
};

const defaults = {
  language: "system",
  petScale: 1,
  selectedPetID: "fufu",
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

const copy = {
  en: {
    settingsTitle: "Settings",
    pet: "Pet",
    reminders: "Reminders",
    behavior: "Behavior",
    language: "Language",
    system: "System",
    english: "English",
    chinese: "Chinese",
    petChoice: "Pet",
    petSize: "Size",
    showPetOnLaunch: "Show pet on launch",
    lowerDistractionMode: "Lower-distraction mode",
    resetPosition: "Reset pet position",
    restEnabled: "Enable rest reminders",
    restInterval: "Rest interval",
    restBlocking: "Enlarge pet during rest",
    blockingDuration: "Blocking duration",
    blockingScale: "Blocking scale",
    waterEnabled: "Enable water reminders",
    waterInterval: "Water interval",
    bubbleDuration: "Bubble duration",
    automaticActions: "Enable automatic actions",
    actionFrequency: "Action frequency",
    automaticRunning: "Enable automatic running",
    runDirection: "Run direction",
    left: "Left",
    right: "Right",
    random: "Random",
    systemNotifications: "System notifications",
    save: "Save",
    refreshPets: "Refresh pets",
    minutes: "min",
    seconds: "sec",
    percent: "%",
    restBubble: "Time for a break",
    waterBubble: "Time to drink water",
    imBack: "I'm back!",
    petdexPath: "PetDex pets are loaded from"
  },
  zh: {
    settingsTitle: "设置",
    pet: "宠物",
    reminders: "提醒",
    behavior: "行为",
    language: "语言",
    system: "跟随系统",
    english: "英文",
    chinese: "中文",
    petChoice: "宠物",
    petSize: "大小",
    showPetOnLaunch: "启动时显示宠物",
    lowerDistractionMode: "低干扰模式",
    resetPosition: "重置宠物位置",
    restEnabled: "开启休息提醒",
    restInterval: "休息间隔",
    restBlocking: "休息时放大挡屏",
    blockingDuration: "挡屏时长",
    blockingScale: "挡屏比例",
    waterEnabled: "开启喝水提醒",
    waterInterval: "喝水间隔",
    bubbleDuration: "气泡显示时长",
    automaticActions: "开启自动动作",
    actionFrequency: "动作频率",
    automaticRunning: "开启自动跑动",
    runDirection: "跑动方向",
    left: "向左",
    right: "向右",
    random: "随机",
    systemNotifications: "系统通知",
    save: "保存",
    refreshPets: "刷新宠物",
    minutes: "分钟",
    seconds: "秒",
    percent: "%",
    restBubble: "休息一下吧",
    waterBubble: "喝点水吧",
    imBack: "我回来啦！",
    petdexPath: "PetDex 宠物读取位置"
  }
};

let preferences = { ...defaults };
let pets = [];
let petdexRoot = "";
let spriteURL = "";
let fallbackSpriteURL = "";
let spriteLoadFailed = false;
let petState = "idle";
let stateStartedAt = performance.now();
let frameTimer;
let blinkTimer;
let inactivityTimer;
let restTimer;
let waterTimer;
let bubbleTimer;
let autoActionTimer;
let autoRunTimer;
let blockingTimer;
let reminderClearTimer;
let dragContext = null;
let previousBounds = null;
let activeReminderKind = null;

function languageKey() {
  if (preferences.language === "chinese") return "zh";
  if (preferences.language === "english") return "en";
  return navigator.language.toLowerCase().startsWith("zh") ? "zh" : "en";
}

function t(key) {
  return copy[languageKey()][key] || copy.en[key] || key;
}

function clamp(number, minimum, maximum) {
  return Math.min(Math.max(Number(number) || minimum, minimum), maximum);
}

function spriteStyleFor(state) {
  const frames = preferences.lowerDistractionMode && state.includes("Running") ? [0, 1] : (stateFrames[state] || stateFrames.idle);
  const frameDuration = preferences.lowerDistractionMode && state === "idle" ? 2000 : state === "sleeping" ? 1000 : 250;
  const elapsed = performance.now() - stateStartedAt;
  const frame = frames[Math.floor(elapsed / frameDuration) % frames.length];
  const row = frameRows[state] ?? 0;
  const columns = 8;
  const rows = 9;
  return {
    backgroundImage: `url("${spriteURL}")`,
    backgroundSize: `${columns * 100}% ${rows * 100}%`,
    backgroundPosition: `${(frame / (columns - 1)) * 100}% ${(row / (rows - 1)) * 100}%`
  };
}

function setPetState(nextState, duration = 0) {
  petState = nextState;
  stateStartedAt = performance.now();
  drawPet();
  if (duration > 0) {
    window.clearTimeout(setPetState.resetTimer);
    setPetState.resetTimer = window.setTimeout(() => {
      if (petState === nextState) setPetState("idle");
    }, duration);
  }
}

function selectedPet() {
  return pets.find((pet) => pet.id === preferences.selectedPetID) || pets[0];
}

function applySelectedPet() {
  const pet = selectedPet();
  preferences.selectedPetID = pet.id;
  spriteURL = api.fileURL(pet.spritesheetPath);
  spriteLoadFailed = false;
  verifySpriteImage(spriteURL);
}

function drawPet() {
  const sprite = document.querySelector(".sprite");
  if (!sprite || !spriteURL) return;
  if (spriteLoadFailed) {
    drawFallbackPet();
    return;
  }
  Object.assign(sprite.style, spriteStyleFor(petState));
}

function drawFallbackPet() {
  const sprite = document.querySelector(".sprite");
  if (!sprite || !fallbackSpriteURL) return;
  sprite.style.backgroundImage = `url("${fallbackSpriteURL}")`;
  sprite.style.backgroundSize = "contain";
  sprite.style.backgroundPosition = "center";
  sprite.style.backgroundRepeat = "no-repeat";
}

function verifySpriteImage(url) {
  const image = new Image();
  image.onerror = () => {
    spriteLoadFailed = true;
    drawFallbackPet();
  };
  image.src = url;
}

function showBubble(message, button = false) {
  const bubble = document.querySelector(".bubble");
  if (!bubble) return;
  bubble.hidden = false;
  bubble.innerHTML = "";
  const text = document.createElement("div");
  text.textContent = message;
  bubble.appendChild(text);
  if (button) {
    const buttonElement = document.createElement("button");
    buttonElement.textContent = t("imBack");
    buttonElement.addEventListener("click", endRestBlocking);
    bubble.appendChild(buttonElement);
  }
  window.clearTimeout(bubbleTimer);
  if (!button) {
    bubbleTimer = window.setTimeout(() => {
      bubble.hidden = true;
    }, clamp(preferences.bubbleDurationSeconds, 1, 60) * 1000);
  }
}

function hideBubble() {
  const bubble = document.querySelector(".bubble");
  if (bubble) bubble.hidden = true;
}

function resetTimers() {
  [blinkTimer, inactivityTimer, restTimer, waterTimer, autoActionTimer, autoRunTimer].forEach((timer) => window.clearInterval(timer));
  blinkTimer = window.setInterval(() => {
    if (petState === "idle") setPetState("automaticBlink", 350);
  }, preferences.lowerDistractionMode ? 9000 : 4200);
  inactivityTimer = window.setInterval(() => {
    if (petState === "idle") setPetState("sleeping");
  }, 30 * 60 * 1000);
  if (preferences.restRemindersEnabled) {
    restTimer = window.setInterval(triggerRestReminder, clamp(preferences.reminderIntervalMinutes, 1, 240) * 60 * 1000);
  }
  if (preferences.waterRemindersEnabled) {
    waterTimer = window.setInterval(triggerWaterReminder, clamp(preferences.waterIntervalMinutes, 1, 480) * 60 * 1000);
  }
  if (preferences.automaticActionsEnabled) {
    autoActionTimer = window.setInterval(playRandomExpressiveAction, clamp(preferences.automaticActionIntervalMinutes, 1, 120) * 60 * 1000);
  }
  if (preferences.automaticRunningEnabled) {
    autoRunTimer = window.setInterval(playAutomaticRun, Math.max(12000, clamp(preferences.automaticActionIntervalMinutes, 1, 120) * 30000));
  }
}

function triggerRestReminder() {
  activeReminderKind = "rest";
  setPetState("waving", 900);
  showBubble(t("restBubble"), preferences.restBlockingEnabled);
  api.notify({ title: "SlackerBuddy", body: t("restBubble") });
  if (preferences.restBlockingEnabled) {
    startRestBlocking();
  }
}

function triggerWaterReminder() {
  activeReminderKind = "water";
  window.clearTimeout(reminderClearTimer);
  setPetState("waving", 900);
  showBubble(t("waterBubble"), false);
  api.notify({ title: "SlackerBuddy", body: t("waterBubble") });
  reminderClearTimer = window.setTimeout(() => {
    if (activeReminderKind === "water") activeReminderKind = null;
  }, clamp(preferences.bubbleDurationSeconds, 1, 60) * 1000);
}

async function startRestBlocking() {
  previousBounds = await api.getPetBounds();
  await api.setBlockingBounds(preferences.restBlockingScalePercent);
  window.clearTimeout(blockingTimer);
  blockingTimer = window.setTimeout(endRestBlocking, clamp(preferences.restBlockingDurationSeconds, 1, 300) * 1000);
}

async function endRestBlocking() {
  window.clearTimeout(blockingTimer);
  window.clearTimeout(reminderClearTimer);
  activeReminderKind = null;
  hideBubble();
  if (previousBounds) {
    await api.setPetBounds(previousBounds);
    previousBounds = null;
  }
  setPetState("idle");
}

function playRandomExpressiveAction() {
  if (activeReminderKind) return;
  if (petState !== "idle") return;
  const states = ["reviewing", "jumping", "failed", "waiting", "running"];
  setPetState(states[Math.floor(Math.random() * states.length)], 1600);
}

async function playAutomaticRun() {
  if (activeReminderKind) return;
  if (petState !== "idle") return;
  let direction = preferences.automaticRunDirectionMode;
  if (direction === "random") direction = Math.random() > 0.5 ? "right" : "left";
  const bounds = await api.getPetBounds();
  const step = direction === "left" ? -120 : 120;
  setPetState(direction === "left" ? "automaticRunningLeft" : "automaticRunningRight", 1200);
  await api.setPetBounds({ ...bounds, x: bounds.x + step });
}

async function beginDrag(event) {
  event.preventDefault();
  const bounds = await api.getPetBounds();
  const cursor = await api.getCursorPoint();
  dragContext = { bounds, cursor };
}

async function continueDrag() {
  if (!dragContext) return;
  const cursor = await api.getCursorPoint();
  const dx = cursor.x - dragContext.cursor.x;
  const dy = cursor.y - dragContext.cursor.y;
  if (Math.abs(dx) > 1) {
    setPetState(dx < 0 ? "dragRunningLeft" : "dragRunningRight");
  }
  await api.setPetBounds({
    ...dragContext.bounds,
    x: dragContext.bounds.x + dx,
    y: dragContext.bounds.y + dy
  });
}

function endDrag() {
  dragContext = null;
  setPetState("idle");
}

function clickPet() {
  const states = ["reviewing", "jumping", "failed", "waiting", "running"];
  setPetState(states[Math.floor(Math.random() * states.length)], 1600);
}

async function renderPet() {
  const initial = await api.getInitialState();
  preferences = { ...defaults, ...initial.preferences };
  pets = initial.pets;
  petdexRoot = initial.petdexRoot;
  fallbackSpriteURL = api.fileURL(initial.assets.fufuIdle);
  applySelectedPet();

  document.body.innerHTML = `
    <div class="pet-shell">
      <div class="pet">
        <div class="sprite"></div>
        <div class="bubble" hidden></div>
      </div>
    </div>
  `;

  const pet = document.querySelector(".pet");
  pet.addEventListener("pointerdown", beginDrag);
  pet.addEventListener("click", clickPet);
  window.addEventListener("pointermove", continueDrag);
  window.addEventListener("pointerup", endDrag);
  frameTimer = window.setInterval(drawPet, 80);
  resetTimers();
  drawPet();
  window.setTimeout(drawFallbackPet, 500);
  api.petReady();
}

function row(label, control) {
  return `<div class="row"><label>${label}</label><div class="control">${control}</div></div>`;
}

function numberInput(key, min, max, suffix) {
  return `<input type="number" min="${min}" max="${max}" step="1" data-setting="${key}" value="${preferences[key]}"><span class="suffix">${suffix}</span>`;
}

function checkbox(key) {
  return `<input type="checkbox" data-setting="${key}" ${preferences[key] ? "checked" : ""}>`;
}

function renderSettingsForm() {
  const petOptions = pets.map((pet) => `<option value="${pet.id}" ${pet.id === preferences.selectedPetID ? "selected" : ""}>${pet.displayName}</option>`).join("");
  return `
    <main class="settings-page">
      <header class="settings-header">
        <div class="settings-brand">
          <img src="../assets/SlackerBuddyAppIcon.png" alt="SlackerBuddy">
          <h1>${t("settingsTitle")}</h1>
        </div>
      </header>

      <section class="settings-section">
        <div class="section-title">${t("pet")}</div>
        ${row(t("language"), `<select data-setting="language"><option value="system">${t("system")}</option><option value="english">${t("english")}</option><option value="chinese">${t("chinese")}</option></select>`)}
        ${row(t("petChoice"), `<select data-setting="selectedPetID">${petOptions}</select>`)}
        ${row(t("petSize"), numberInput("petScale", 0.5, 3, "x"))}
        ${row(t("showPetOnLaunch"), checkbox("showPetOnLaunch"))}
        ${row(t("lowerDistractionMode"), checkbox("lowerDistractionMode"))}
        <div class="row"><label>${t("petdexPath")}</label><div class="control"><span class="petdex-path">${petdexRoot}</span></div></div>
      </section>

      <section class="settings-section">
        <div class="section-title">${t("reminders")}</div>
        ${row(t("restEnabled"), checkbox("restRemindersEnabled"))}
        ${row(t("restInterval"), numberInput("reminderIntervalMinutes", 1, 240, t("minutes")))}
        ${row(t("restBlocking"), checkbox("restBlockingEnabled"))}
        ${row(t("blockingDuration"), numberInput("restBlockingDurationSeconds", 1, 300, t("seconds")))}
        ${row(t("blockingScale"), numberInput("restBlockingScalePercent", 10, 90, t("percent")))}
        ${row(t("waterEnabled"), checkbox("waterRemindersEnabled"))}
        ${row(t("waterInterval"), numberInput("waterIntervalMinutes", 1, 480, t("minutes")))}
        ${row(t("bubbleDuration"), numberInput("bubbleDurationSeconds", 1, 60, t("seconds")))}
      </section>

      <section class="settings-section">
        <div class="section-title">${t("behavior")}</div>
        ${row(t("automaticActions"), checkbox("automaticActionsEnabled"))}
        ${row(t("actionFrequency"), numberInput("automaticActionIntervalMinutes", 1, 120, t("minutes")))}
        ${row(t("automaticRunning"), checkbox("automaticRunningEnabled"))}
        ${row(t("runDirection"), `<select data-setting="automaticRunDirectionMode"><option value="left">${t("left")}</option><option value="right">${t("right")}</option><option value="random">${t("random")}</option></select>`)}
        ${row(t("systemNotifications"), checkbox("systemNotificationsEnabled"))}
      </section>

      <div class="button-row">
        <button class="secondary-button" data-action="refresh">${t("refreshPets")}</button>
        <button class="secondary-button" data-action="reset">${t("resetPosition")}</button>
        <button class="primary" data-action="save">${t("save")}</button>
      </div>
    </main>
  `;
}

async function renderSettings() {
  const initial = await api.getInitialState();
  preferences = { ...defaults, ...initial.preferences };
  pets = initial.pets;
  petdexRoot = initial.petdexRoot;
  document.body.innerHTML = renderSettingsForm();
  document.querySelector('[data-setting="language"]').value = preferences.language;
  document.querySelector('[data-setting="automaticRunDirectionMode"]').value = preferences.automaticRunDirectionMode;

  document.querySelector('[data-action="save"]').addEventListener("click", saveSettingsFromForm);
  document.querySelector('[data-action="refresh"]').addEventListener("click", async () => {
    pets = await api.refreshPets();
    await renderSettings();
  });
  document.querySelector('[data-action="reset"]').addEventListener("click", async () => {
    await api.setPetBounds({ x: 80, y: 80, width: 220, height: 220 });
  });
}

async function saveSettingsFromForm() {
  const next = { ...preferences };
  document.querySelectorAll("[data-setting]").forEach((element) => {
    const key = element.dataset.setting;
    if (element.type === "checkbox") {
      next[key] = element.checked;
    } else if (element.type === "number") {
      next[key] = Number(element.value);
    } else {
      next[key] = element.value;
    }
  });
  preferences = await api.saveSettings(next);
  await api.resizePet(preferences.petScale);
  await renderSettings();
}

api.onPreferencesUpdated((nextPreferences) => {
  preferences = { ...defaults, ...nextPreferences };
  if (windowKind === "pet") {
    applySelectedPet();
    resetTimers();
  }
});

if (windowKind === "settings") {
  renderSettings();
} else {
  renderPet();
}

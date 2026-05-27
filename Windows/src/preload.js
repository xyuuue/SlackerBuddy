const { contextBridge, ipcRenderer } = require("electron");
const { pathToFileURL } = require("url");

contextBridge.exposeInMainWorld("slackerBuddy", {
  getInitialState: () => ipcRenderer.invoke("app:get-initial-state"),
  saveSettings: (preferences) => ipcRenderer.invoke("settings:save", preferences),
  refreshPets: () => ipcRenderer.invoke("petdex:refresh"),
  getPetBounds: () => ipcRenderer.invoke("pet:get-bounds"),
  setPetBounds: (bounds) => ipcRenderer.invoke("pet:set-bounds", bounds),
  resizePet: (scale) => ipcRenderer.invoke("pet:resize", scale),
  setBlockingBounds: (scalePercent) => ipcRenderer.invoke("pet:blocking-bounds", scalePercent),
  getCursorPoint: () => ipcRenderer.invoke("screen:get-cursor-point"),
  notify: (payload) => ipcRenderer.invoke("notify", payload),
  openSettings: () => ipcRenderer.send("settings:open"),
  showPet: () => ipcRenderer.send("pet:show"),
  hidePet: () => ipcRenderer.send("pet:hide"),
  fileURL: (filePath) => pathToFileURL(filePath).toString(),
  onPreferencesUpdated: (callback) => ipcRenderer.on("preferences-updated", (_event, preferences) => callback(preferences))
});

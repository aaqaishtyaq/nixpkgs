{ ... }:

let
  # Stable feature IDs from Vorssaint's feature catalog. Anything outside the
  # selected set stays uninstalled and therefore does not load at runtime.
  allFeatures = [
    "appUpdates"
    "autoQuit"
    "bluetoothSleep"
    "brightness"
    "cameraPreview"
    "cleaner"
    "cleaningMode"
    "clipboardHistory"
    "colorPicker"
    "commandBar"
    "diskImageInstaller"
    "dockClick"
    "dockPreview"
    "extraBrightness"
    "fanControl"
    "finderCutPaste"
    "finderRename"
    "focusFollowsMouse"
    "homebrew"
    "keepAwake"
    "keyboardDebounce"
    "killProcess"
    "mediaTools"
    "micMute"
    "middleClick"
    "mixer"
    "monitorCPU"
    "monitorDisk"
    "monitorGPU"
    "monitorMemory"
    "monitorNetwork"
    "monitorPower"
    "mouseAcceleration"
    "mouseButtonShortcuts"
    "mouseClickDebounce"
    "mouseNavigation"
    "musicBlock"
    "notch"
    "notchAccessories"
    "notchCalendar"
    "notchDownloads"
    "notchGestures"
    "notchLyrics"
    "notchNotifications"
    "notchQueue"
    "notchTimer"
    "pastePlain"
    "quickLauncher"
    "quickToggles"
    "quitWindowProtection"
    "radialMenu"
    "scratchpad"
    "screenOCR"
    "screenRecorder"
    "screenshot"
    "scrollInverter"
    "shelf"
    "smoothScroll"
    "soundOutputSwitcher"
    "superKey"
    "switcher"
    "textSnippets"
    "uninstaller"
    "urlCleaner"
    "windowLayout"
    "windowMaximizer"
  ];

  enabledFeatures = [
    "appUpdates"
    "cleaningMode"
    "colorPicker"
    "dockPreview"
    "keepAwake"
    "mediaTools"
    "screenshot"
    "switcher"
    "uninstaller"
    "urlCleaner"
    "windowLayout"
  ];

  featurePreferences = builtins.listToAttrs (
    map (feature: {
      name = "featureAvailable.${feature}";
      value = builtins.elem feature enabledFeatures;
    }) allFeatures
  );
in
{
  # Vorssaint stores feature availability in the standard macOS preferences
  # domain. Manage those switches through nix-darwin rather than symlinking
  # cfprefsd's plist.
  system.defaults.CustomUserPreferences."com.vorssaint.utils" = featurePreferences // {
    dockPreviewEnabled = true;
    launchAtLoginWanted = true;
    switcherEnabled = false;
    windowLayoutShortcutsEnabled = true;
  };
}

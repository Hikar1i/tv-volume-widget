import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'services/settings_service.dart';
import 'services/audio_service.dart';
import 'utils/fullscreen_detector.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize settings
  await SettingsService().init();

  // Initialize window
  doWhenWindowReady(() {
    final settings = SettingsService();
    final initialSize = const Size(480, 640);

    appWindow.size = initialSize;
    appWindow.minSize = const Size(400, 500);
    appWindow.maxSize = const Size(600, 900);
    appWindow.alignment = Alignment.center;
    appWindow.title = 'TV Volume Widget';
    appWindow.show();

    // Restore window position if saved
    if (settings.windowX >= 0 && settings.windowY >= 0) {
      appWindow.position = Offset(settings.windowX, settings.windowY);
    }

    // Set always on top
    if (settings.alwaysOnTop) {
      appWindow.setAsFrameless();
    }
  });

  // Register hotkeys
  await _registerHotkeys();

  // Start fullscreen detector
  if (SettingsService().hideInFullscreen) {
    FullscreenDetector().start();
  }

  runApp(const TvVolumeWidgetApp());
}

Future<void> _registerHotkeys() async {
  final settings = SettingsService();
  if (!settings.hotkeysEnabled) return;

  final audioService = AudioService();

  // Volume Up: Ctrl+Alt+Up
  final volumeUpKey = HotKey(
    KeyCode.up,
    modifiers: [KeyModifier.control, KeyModifier.alt],
    scope: HotKeyScope.system,
  );
  await hotKeyManager.register(
    volumeUpKey,
    keyDownHandler: (hotKey) async {
      final volume = await audioService.getVolume();
      await audioService.setVolume((volume + 0.01).clamp(0.0, 1.0));
    },
  );

  // Volume Down: Ctrl+Alt+Down
  final volumeDownKey = HotKey(
    KeyCode.down,
    modifiers: [KeyModifier.control, KeyModifier.alt],
    scope: HotKeyScope.system,
  );
  await hotKeyManager.register(
    volumeDownKey,
    keyDownHandler: (hotKey) async {
      final volume = await audioService.getVolume();
      await audioService.setVolume((volume - 0.01).clamp(0.0, 1.0));
    },
  );

  // Mute Toggle: Ctrl+Alt+M
  final muteKey = HotKey(
    KeyCode.keyM,
    modifiers: [KeyModifier.control, KeyModifier.alt],
    scope: HotKeyScope.system,
  );
  await hotKeyManager.register(
    muteKey,
    keyDownHandler: (hotKey) async {
      final muted = await audioService.getMute();
      await audioService.setMute(!muted);
    },
  );
}

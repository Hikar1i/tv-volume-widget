import 'dart:ffi' hide Size;
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:win32/win32.dart';
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
  });

  // Register global hotkeys via Win32
  _registerHotkeys();

  // Start fullscreen detector
  if (SettingsService().hideInFullscreen) {
    FullscreenDetector().start();
  }

  runApp(const TvVolumeWidgetApp());
}

// Win32 modifier constants for RegisterHotKey
const _kModControl = 0x0002; // MOD_CONTROL
const _kModAlt = 0x0001; // MOD_ALT

// Hotkey IDs
const _kHotkeyIdVolumeUp = 1;
const _kHotkeyIdVolumeDown = 2;
const _kHotkeyIdMute = 3;

void _registerHotkeys() {
  final settings = SettingsService();
  if (!settings.hotkeysEnabled) return;

  final mods = _kModControl | _kModAlt;
  // Ctrl+Alt+Up -> Volume Up
  RegisterHotKey(0, _kHotkeyIdVolumeUp, mods, VK_UP);
  // Ctrl+Alt+Down -> Volume Down
  RegisterHotKey(0, _kHotkeyIdVolumeDown, mods, VK_DOWN);
  // Ctrl+Alt+M -> Mute toggle
  RegisterHotKey(0, _kHotkeyIdMute, mods, 0x4D); // 'M'

  // Listen for hotkey messages
  _startHotkeyListener();
}

void _startHotkeyListener() async {
  final audioService = AudioService();
  final msg = calloc<MSG>();

  while (true) {
    await Future.delayed(const Duration(milliseconds: 50));

    while (PeekMessage(msg, 0, 0, 0, PM_REMOVE) != 0) {
      if (msg.ref.message == WM_HOTKEY) {
        final id = msg.ref.wParam;
        switch (id) {
          case _kHotkeyIdVolumeUp:
            final vol = await audioService.getVolume();
            await audioService.setVolume((vol + 0.01).clamp(0.0, 1.0));
            break;
          case _kHotkeyIdVolumeDown:
            final vol = await audioService.getVolume();
            await audioService.setVolume((vol - 0.01).clamp(0.0, 1.0));
            break;
          case _kHotkeyIdMute:
            final muted = await audioService.getMute();
            await audioService.setMute(!muted);
            break;
        }
      }
      TranslateMessage(msg);
      DispatchMessage(msg);
    }
  }
}

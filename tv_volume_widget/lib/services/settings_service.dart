import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._();
  factory SettingsService() => _instance;
  SettingsService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Theme index (0-4 for the 5 Morandi presets)
  int get themeIndex => _prefs?.getInt('themeIndex') ?? 0;
  set themeIndex(int value) => _prefs?.setInt('themeIndex', value);

  // Window opacity (0.2 - 1.0)
  double get opacity => _prefs?.getDouble('opacity') ?? 0.95;
  set opacity(double value) => _prefs?.setDouble('opacity', value);

  // Always on top
  bool get alwaysOnTop => _prefs?.getBool('alwaysOnTop') ?? true;
  set alwaysOnTop(bool value) => _prefs?.setBool('alwaysOnTop', value);

  // Auto-start (launch at Windows startup)
  bool get autoStart => _prefs?.getBool('autoStart') ?? false;
  set autoStart(bool value) => _prefs?.setBool('autoStart', value);

  // Window position X
  double get windowX => _prefs?.getDouble('windowX') ?? -1;
  set windowX(double value) => _prefs?.setDouble('windowX', value);

  // Window position Y
  double get windowY => _prefs?.getDouble('windowY') ?? -1;
  set windowY(double value) => _prefs?.setDouble('windowY', value);

  // Hotkeys enabled
  bool get hotkeysEnabled => _prefs?.getBool('hotkeysEnabled') ?? true;
  set hotkeysEnabled(bool value) => _prefs?.setBool('hotkeysEnabled', value);

  // Hide in fullscreen mode
  bool get hideInFullscreen => _prefs?.getBool('hideInFullscreen') ?? true;
  set hideInFullscreen(bool value) => _prefs?.setBool('hideInFullscreen', value);

  // Last used device ID
  String? get lastDeviceId => _prefs?.getString('lastDeviceId');
  set lastDeviceId(String? value) {
    if (value != null) {
      _prefs?.setString('lastDeviceId', value);
    } else {
      _prefs?.remove('lastDeviceId');
    }
  }
}

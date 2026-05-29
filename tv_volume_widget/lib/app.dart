import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'models/app_theme.dart';
import 'services/settings_service.dart';

class TvVolumeWidgetApp extends StatelessWidget {
  const TvVolumeWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService();
    final themeIndex = settings.themeIndex;
    final theme = MorandiTheme.presets[themeIndex.clamp(0, MorandiTheme.presets.length - 1)];

    return MaterialApp(
      title: 'TV Volume Widget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: ColorScheme.dark(
          primary: theme.primary,
          surface: theme.surface,
        ),
        fontFamily: 'Segoe UI',
      ),
      home: const _AppHome(),
    );
  }
}

class _AppHome extends StatefulWidget {
  const _AppHome();

  @override
  State<_AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<_AppHome> {
  final _settings = SettingsService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: HomeScreen(
          onClose: () {
            // Minimize to tray instead of closing
            _minimizeToTray();
          },
          onMinimize: () {
            _minimizeToTray();
          },
        ),
      ),
    );
  }

  void _minimizeToTray() {
    // For now, just minimize the window
    // System tray integration will be added later
  }
}

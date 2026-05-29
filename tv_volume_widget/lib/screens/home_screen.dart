import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/audio_device.dart';
import '../models/app_theme.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../widgets/title_bar.dart';
import '../widgets/audio_device_card.dart';
import '../widgets/volume_slider.dart';
import '../widgets/theme_picker.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final VoidCallback? onMinimize;

  const HomeScreen({super.key, this.onClose, this.onMinimize});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _audioService = AudioService();
  final _settings = SettingsService();

  List<AudioDevice> _devices = [];
  AudioDevice? _currentDevice;
  double _volume = 0.0;
  bool _isMuted = false;
  int _themeIndex = 0;
  double _opacity = 0.95;
  bool _showSettings = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _themeIndex = _settings.themeIndex;
    _opacity = _settings.opacity;
    _refreshDevices();
    _refreshVolume();

    // Periodically refresh volume and devices
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _refreshVolume();
      _refreshDevices();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  MorandiTheme get _currentTheme => MorandiTheme.presets[_themeIndex];

  Future<void> _refreshDevices() async {
    try {
      final devices = await _audioService.getOutputDevices();
      final current = await _audioService.getDefaultDevice();
      if (mounted) {
        setState(() {
          _devices = devices;
          _currentDevice = current;
        });
      }
    } catch (e) {
      print('Error refreshing devices: $e');
    }
  }

  Future<void> _refreshVolume() async {
    try {
      final volume = await _audioService.getVolume();
      final muted = await _audioService.getMute();
      if (mounted) {
        setState(() {
          _volume = volume;
          _isMuted = muted;
        });
      }
    } catch (e) {
      print('Error refreshing volume: $e');
    }
  }

  Future<void> _switchDevice(AudioDevice device) async {
    final success = await _audioService.setDefaultDevice(device);
    if (success) {
      _settings.lastDeviceId = device.id;
      await _refreshDevices();
      await _refreshVolume();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到: ${device.name}'),
            backgroundColor: _currentTheme.primary.withOpacity(0.9),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _setVolume(double volume) async {
    await _audioService.setVolume(volume);
    setState(() => _volume = volume);
  }

  Future<void> _toggleMute() async {
    final newMute = !_isMuted;
    await _audioService.setMute(newMute);
    setState(() => _isMuted = newMute);
  }

  void _setTheme(int index) {
    setState(() => _themeIndex = index);
    _settings.themeIndex = index;
  }

  void _setOpacity(double value) {
    setState(() => _opacity = value);
    _settings.opacity = value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = _currentTheme;

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 720),
        decoration: BoxDecoration(
          color: theme.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            CustomTitleBar(
              primaryColor: theme.primary,
              onMinimize: widget.onMinimize,
              onClose: widget.onClose,
              onSettings: () => setState(() => _showSettings = !_showSettings),
            ),

            // Main content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Volume section
                    VolumeSlider(
                      volume: _volume,
                      isMuted: _isMuted,
                      onChanged: _setVolume,
                      onChangeEnd: (v) => _audioService.setVolume(v),
                      onMuteToggle: _toggleMute,
                      primaryColor: theme.primary,
                      surfaceColor: theme.surface,
                      onSurfaceColor: theme.onSurface,
                    ),

                    const SizedBox(height: 8),

                    // Devices section header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.surround_sound,
                            color: theme.onSurface.withOpacity(0.5),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '音频输出设备',
                            style: TextStyle(
                              color: theme.onSurface.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_devices.length} 个设备',
                            style: TextStyle(
                              color: theme.onSurface.withOpacity(0.4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Device list
                    if (_devices.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.speaker_group,
                                color: theme.onSurface.withOpacity(0.3),
                                size: 48,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '未检测到音频设备',
                                style: TextStyle(
                                  color: theme.onSurface.withOpacity(0.4),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_devices.length, (index) {
                        final device = _devices[index];
                        final isActive = _currentDevice?.id == device.id;
                        return AudioDeviceCard(
                          device: device,
                          isActive: isActive,
                          onTap: () => _switchDevice(device),
                          primaryColor: theme.primary,
                          surfaceColor: theme.surface,
                          onSurfaceColor: theme.onSurface,
                        );
                      }),

                    const SizedBox(height: 16),

                    // Settings panel
                    if (_showSettings) ...[
                      SettingsPanel(
                        opacity: _opacity,
                        onOpacityChanged: _setOpacity,
                        alwaysOnTop: _settings.alwaysOnTop,
                        onAlwaysOnTopChanged: (v) {
                          setState(() => _settings.alwaysOnTop = v);
                        },
                        hotkeysEnabled: _settings.hotkeysEnabled,
                        onHotkeysEnabledChanged: (v) {
                          setState(() => _settings.hotkeysEnabled = v);
                        },
                        hideInFullscreen: _settings.hideInFullscreen,
                        onHideInFullscreenChanged: (v) {
                          setState(() => _settings.hideInFullscreen = v);
                        },
                        primaryColor: theme.primary,
                        surfaceColor: theme.surface,
                        onSurfaceColor: theme.onSurface,
                      ),
                      const SizedBox(height: 8),
                      // Theme picker
                      Center(
                        child: ThemePicker(
                          selectedIndex: _themeIndex,
                          onThemeSelected: _setTheme,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bottom padding
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

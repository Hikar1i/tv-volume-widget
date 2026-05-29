import 'package:flutter/material.dart';
import '../models/app_theme.dart';

class ThemePicker extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onThemeSelected;

  const ThemePicker({
    super.key,
    required this.selectedIndex,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(MorandiTheme.presets.length, (index) {
        final theme = MorandiTheme.presets[index];
        final isSelected = index == selectedIndex;
        return GestureDetector(
          onTap: () => onThemeSelected(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isSelected ? 48 : 40,
            height: isSelected ? 48 : 40,
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.primary.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }),
    );
  }
}

class SettingsPanel extends StatelessWidget {
  final double opacity;
  final ValueChanged<double> onOpacityChanged;
  final bool alwaysOnTop;
  final ValueChanged<bool> onAlwaysOnTopChanged;
  final bool hotkeysEnabled;
  final ValueChanged<bool> onHotkeysEnabledChanged;
  final bool hideInFullscreen;
  final ValueChanged<bool> onHideInFullscreenChanged;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  const SettingsPanel({
    super.key,
    required this.opacity,
    required this.onOpacityChanged,
    required this.alwaysOnTop,
    required this.onAlwaysOnTopChanged,
    required this.hotkeysEnabled,
    required this.onHotkeysEnabledChanged,
    required this.hideInFullscreen,
    required this.onHideInFullscreenChanged,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme section
          Text(
            '主题色',
            style: TextStyle(
              color: onSurfaceColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ThemePicker(
            selectedIndex: 0, // Will be controlled by parent
            onThemeSelected: (_) {},
          ),
          const SizedBox(height: 20),

          // Opacity section
          Row(
            children: [
              Icon(Icons.opacity, color: onSurfaceColor.withOpacity(0.5), size: 20),
              const SizedBox(width: 8),
              Text(
                '透明度',
                style: TextStyle(
                  color: onSurfaceColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '${(opacity * 100).round()}%',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Slider(
            value: opacity,
            min: 0.2,
            max: 1.0,
            divisions: 80,
            onChanged: onOpacityChanged,
            activeColor: primaryColor,
            inactiveColor: surfaceColor,
          ),
          const SizedBox(height: 12),

          // Toggle options
          _ToggleRow(
            label: '窗口置顶',
            icon: Icons.push_pin,
            value: alwaysOnTop,
            onChanged: onAlwaysOnTopChanged,
            primaryColor: primaryColor,
            onSurfaceColor: onSurfaceColor,
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            label: '全局热键',
            icon: Icons.keyboard,
            value: hotkeysEnabled,
            onChanged: onHotkeysEnabledChanged,
            primaryColor: primaryColor,
            onSurfaceColor: onSurfaceColor,
          ),
          const SizedBox(height: 8),
          _ToggleRow(
            label: '全屏时隐藏',
            icon: Icons.fullscreen_exit,
            value: hideInFullscreen,
            onChanged: onHideInFullscreenChanged,
            primaryColor: primaryColor,
            onSurfaceColor: onSurfaceColor,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primaryColor;
  final Color onSurfaceColor;

  const _ToggleRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
    required this.primaryColor,
    required this.onSurfaceColor,
  });

  @override
  Widget build(BuildContext buildContext) {
    return Row(
      children: [
        Icon(icon, color: onSurfaceColor.withOpacity(0.5), size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: onSurfaceColor.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: primaryColor,
        ),
      ],
    );
  }
}

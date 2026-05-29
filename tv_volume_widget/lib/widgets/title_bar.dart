import 'package:flutter/material.dart';

class CustomTitleBar extends StatelessWidget {
  final VoidCallback? onMinimize;
  final VoidCallback? onClose;
  final VoidCallback? onSettings;
  final Color primaryColor;

  const CustomTitleBar({
    super.key,
    this.onMinimize,
    this.onClose,
    this.onSettings,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (_) {
        // Allow dragging the window by the title bar
        // This is handled by the native window manager
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(Icons.speaker, color: primaryColor, size: 24),
            const SizedBox(width: 12),
            const Text(
              'TV Volume Widget',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            _WindowButton(
              icon: Icons.minimize,
              onTap: onMinimize,
              tooltip: '最小化',
            ),
            _WindowButton(
              icon: Icons.settings,
              onTap: onSettings,
              tooltip: '设置',
            ),
            _WindowButton(
              icon: Icons.close,
              onTap: onClose,
              tooltip: '关闭',
              isClose: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool isClose;

  const _WindowButton({
    required this.icon,
    this.onTap,
    this.tooltip = '',
    this.isClose = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: _hovered
                  ? (widget.isClose
                      ? Colors.red.withOpacity(0.8)
                      : Colors.white.withOpacity(0.1))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              widget.icon,
              color: _hovered && widget.isClose ? Colors.white : Colors.white54,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

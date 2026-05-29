import 'package:flutter/material.dart';
import '../models/audio_device.dart';

class AudioDeviceCard extends StatefulWidget {
  final AudioDevice device;
  final bool isActive;
  final VoidCallback onTap;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  const AudioDeviceCard({
    super.key,
    required this.device,
    required this.isActive,
    required this.onTap,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  State<AudioDeviceCard> createState() => _AudioDeviceCardState();
}

class _AudioDeviceCardState extends State<AudioDeviceCard>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData _getDeviceIcon() {
    switch (widget.device.type) {
      case 'tv':
        return Icons.tv;
      case 'headphone':
        return Icons.headphones;
      case 'headset':
        return Icons.headset_mic;
      case 'bluetooth':
        return Icons.bluetooth_audio;
      case 'usb':
        return Icons.usb;
      case 'digital':
        return Icons.surround_sound;
      case 'speaker':
      default:
        return Icons.speaker;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTapDown: (_) => _controller.forward(),
          onTapUp: (_) {
            _controller.reverse();
            widget.onTap();
          },
          onTapCancel: () => _controller.reverse(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? widget.primaryColor.withOpacity(0.15)
                  : _hovered
                      ? widget.surfaceColor.withOpacity(0.8)
                      : widget.surfaceColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isActive
                    ? widget.primaryColor.withOpacity(0.6)
                    : _hovered
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.05),
                width: widget.isActive ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Device icon
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.isActive
                        ? widget.primaryColor.withOpacity(0.2)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getDeviceIcon(),
                    color: widget.isActive
                        ? widget.primaryColor
                        : widget.onSurfaceColor.withOpacity(0.6),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Device name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.device.name,
                        style: TextStyle(
                          color: widget.isActive
                              ? Colors.white
                              : widget.onSurfaceColor.withOpacity(0.9),
                          fontSize: 18,
                          fontWeight:
                              widget.isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.isActive) ...[
                        const SizedBox(height: 4),
                        Text(
                          '当前设备',
                          style: TextStyle(
                            color: widget.primaryColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Status indicator
                if (widget.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '使用中',
                          style: TextStyle(
                            color: widget.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: widget.onSurfaceColor.withOpacity(0.3),
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

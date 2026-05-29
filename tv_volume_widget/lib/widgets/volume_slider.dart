import 'package:flutter/material.dart';

class VolumeSlider extends StatefulWidget {
  final double volume; // 0.0 - 1.0
  final bool isMuted;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback onMuteToggle;
  final Color primaryColor;
  final Color surfaceColor;
  final Color onSurfaceColor;

  const VolumeSlider({
    super.key,
    required this.volume,
    required this.isMuted,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onMuteToggle,
    required this.primaryColor,
    required this.surfaceColor,
    required this.onSurfaceColor,
  });

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  bool _hovered = false;
  bool _dragging = false;
  double _dragValue = 0;

  IconData _getVolumeIcon() {
    if (widget.isMuted) return Icons.volume_off;
    final volume = widget.volume;
    if (volume <= 0) return Icons.volume_mute;
    if (volume < 0.3) return Icons.volume_down;
    if (volume < 0.7) return Icons.volume_up;
    return Icons.volume_up;
  }

  int get _displayPercent =>
      ((_dragging ? _dragValue : widget.volume) * 100).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          // Volume icon and percentage
          Row(
            children: [
              GestureDetector(
                onTap: widget.onMuteToggle,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: widget.isMuted
                          ? Colors.red.withOpacity(0.15)
                          : widget.primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getVolumeIcon(),
                      color: widget.isMuted
                          ? Colors.red.shade300
                          : widget.primaryColor,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '系统音量',
                      style: TextStyle(
                        color: widget.onSurfaceColor.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_displayPercent%',
                      style: TextStyle(
                        color: widget.isMuted
                            ? Colors.red.shade300
                            : Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Large slider
          MouseRegion(
            onEnter: (_) => setState(() => _hovered = true),
            onExit: (_) => setState(() => _hovered = false),
            child: Listener(
              onPointerDown: (_) => setState(() => _dragging = true),
              onPointerUp: (_) {
                setState(() => _dragging = false);
                widget.onChangeEnd(_dragValue);
              },
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: widget.isMuted
                      ? Colors.red.shade300
                      : widget.primaryColor,
                  inactiveTrackColor: widget.surfaceColor,
                  thumbColor: widget.isMuted
                      ? Colors.red.shade300
                      : widget.primaryColor,
                  overlayColor: (widget.isMuted
                          ? Colors.red
                          : widget.primaryColor)
                      .withOpacity(0.2),
                  thumbShape: _LargeSliderThumb(
                    color: widget.isMuted
                        ? Colors.red.shade300
                        : widget.primaryColor,
                    hovered: _hovered || _dragging,
                  ),
                  trackHeight: 8,
                  trackShape: _RoundedTrackShape(),
                ),
                child: Slider(
                  value: widget.volume.clamp(0.0, 1.0),
                  onChanged: (v) {
                    setState(() => _dragValue = v);
                    widget.onChanged(v);
                  },
                  onChangeEnd: widget.onChangeEnd,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeSliderThumb extends SliderComponentShape {
  final Color color;
  final bool hovered;

  const _LargeSliderThumb({required this.color, this.hovered = false});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size(hovered ? 24 : 20, hovered ? 24 : 20);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final radius = hovered ? 12.0 : 10.0;

    // Shadow
    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center + const Offset(0, 2), radius, shadowPaint);

    // Thumb
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Inner dot
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, innerPaint);
  }
}

class _RoundedTrackShape extends SliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 8;
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    return Rect.fromLTWH(
        offset.dx + 24, trackTop, parentBox.size.width - 48, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final activeRect = Rect.fromLTRB(
      rect.left,
      rect.top,
      thumbCenter.dx,
      rect.bottom,
    );

    final inactiveRect = Rect.fromLTRB(
      thumbCenter.dx,
      rect.top,
      rect.right,
      rect.bottom,
    );

    final radius = Radius.circular(rect.height / 2);

    // Active track
    final activePaint = Paint()
      ..color = sliderTheme.activeTrackColor ?? Colors.blue;
    context.canvas.drawRRect(
        RRect.fromRectAndCorners(activeRect,
            topLeft: radius, bottomLeft: radius),
        activePaint);

    // Inactive track
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? Colors.grey;
    context.canvas.drawRRect(
        RRect.fromRectAndCorners(inactiveRect,
            topRight: radius, bottomRight: radius),
        inactivePaint);
  }
}

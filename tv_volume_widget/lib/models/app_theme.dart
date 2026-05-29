import 'package:flutter/material.dart';

class MorandiTheme {
  final String name;
  final String nameEn;
  final Color primary;
  final Color background;
  final Color surface;
  final Color onSurface;

  const MorandiTheme({
    required this.name,
    required this.nameEn,
    required this.primary,
    required this.background,
    required this.surface,
    required this.onSurface,
  });

  static const List<MorandiTheme> presets = [
    MorandiTheme(
      name: '烟粉',
      nameEn: 'Dusty Pink',
      primary: Color(0xFFD4A5A5),
      background: Color(0xFF1E1E1E),
      surface: Color(0xFF2C2C2C),
      onSurface: Color(0xFFE8E0E0),
    ),
    MorandiTheme(
      name: '雾蓝',
      nameEn: 'Misty Blue',
      primary: Color(0xFF7FAABE),
      background: Color(0xFF1A1E22),
      surface: Color(0xFF252A30),
      onSurface: Color(0xFFD8E4EA),
    ),
    MorandiTheme(
      name: '灰绿',
      nameEn: 'Sage Green',
      primary: Color(0xFF9CAF88),
      background: Color(0xFF1C2018),
      surface: Color(0xFF282E24),
      onSurface: Color(0xFFDDE5D6),
    ),
    MorandiTheme(
      name: '暖杏',
      nameEn: 'Warm Apricot',
      primary: Color(0xFFD4A574),
      background: Color(0xFF201C18),
      surface: Color(0xFF2E2820),
      onSurface: Color(0xFFE8DDD0),
    ),
    MorandiTheme(
      name: '藕紫',
      nameEn: 'Lavender Grey',
      primary: Color(0xFF9B8EA8),
      background: Color(0xFF1E1C22),
      surface: Color(0xFF2A2830),
      onSurface: Color(0xFFE0DCE8),
    ),
  ];
}

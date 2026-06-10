import 'package:flutter/material.dart';

/// Solo Leveling "System" palette — dark void backgrounds with neon purple/blue.
class AppColors {
  static const bg = Color(0xFF07070F);
  static const bg2 = Color(0xFF0D0D1A);
  static const bg3 = Color(0xFF111124);
  static const purple = Color(0xFF7C5CFC);
  static const blue = Color(0xFF3D9BFF);
  static const gold = Color(0xFFF0B429);
  static const red = Color(0xFFFF4757);
  static const green = Color(0xFF2ED573);
  static const cyan = Color(0xFF00D2FF);
  static const text = Color(0xFFC8C8E8);
  static const textDim = Color(0xFF6B6B9A);
  static const textBright = Color(0xFFE8E8FF);
  static const border = Color(0x337C5CFC);
  static const borderBright = Color(0x807C5CFC);
}

const String kMono = 'ShareTechMono';
const String kSans = 'Rajdhani';

ThemeData buildTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    primaryColor: AppColors.purple,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.purple,
      secondary: AppColors.blue,
      surface: AppColors.bg2,
      error: AppColors.red,
    ),
    textTheme: base.textTheme.apply(
      fontFamily: kSans,
      bodyColor: AppColors.text,
      displayColor: AppColors.textBright,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bg3,
      hintStyle: const TextStyle(color: AppColors.textDim),
      labelStyle: const TextStyle(color: AppColors.textDim),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: AppColors.purple),
      ),
    ),
  );
}

/// Shared decoration for the "system panel" look.
BoxDecoration panelDecoration({Color? glow}) => BoxDecoration(
      color: AppColors.bg2,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(2),
      boxShadow: glow == null
          ? null
          : [BoxShadow(color: glow.withValues(alpha: 0.25), blurRadius: 18)],
    );

TextStyle monoStyle({
  double size = 12,
  Color color = AppColors.textDim,
  double spacing = 2,
  FontWeight weight = FontWeight.w400,
}) =>
    TextStyle(
      fontFamily: kMono,
      fontSize: size,
      color: color,
      letterSpacing: spacing,
      fontWeight: weight,
    );

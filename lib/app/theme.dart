import 'package:flutter/material.dart';

/// Dark, photo-first. Photos supply the colour; the UI stays out of the way.
class AppTheme {
  AppTheme._();

  static const accent = Color(0xFFFF6B4A);
  static const bg = Color(0xFF0B0B0D);
  static const surface = Color(0xFF17171B);

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: accent,
      brightness: Brightness.dark,
      surface: surface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 11)),
      ),
      chipTheme: ChipThemeData(
        selectedColor: accent.withValues(alpha: 0.25),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontSize: 13),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

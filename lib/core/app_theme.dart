import 'package:flutter/material.dart';

class AppTheme {
  static const _seed = Color(0xFF0F766E);

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme;
    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return base.copyWith(
      textTheme: text.copyWith(
        headlineLarge: text.headlineLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineSmall: text.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: scheme.outlineVariant,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: rounded,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: rounded,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
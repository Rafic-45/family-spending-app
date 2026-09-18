import 'package:flutter/material.dart';

const Color _seed = Color(0xFF2E7D5B); // calm green

ThemeData buildLightTheme() => _themeFor(Brightness.light);
ThemeData buildDarkTheme() => _themeFor(Brightness.dark);

ThemeData _themeFor(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}

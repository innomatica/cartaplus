import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme(ColorScheme? colorScheme) {
    ColorScheme scheme = colorScheme ??
        ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.indigoAccent,
        );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }

  static ThemeData darkTheme(ColorScheme? colorScheme) {
    ColorScheme scheme = colorScheme ??
        ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.indigoAccent,
        );
    return ThemeData(colorScheme: scheme, useMaterial3: true);
  }
}

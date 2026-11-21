import 'package:flutter/material.dart';

/// Tema visual de Ja'Map inspirado en el agua (cenotes y estanques).
class AppTheme {
  AppTheme._();

  static const Color primaryWater = Color(0xFF0284C7);
  static const Color deepPond = Color(0xFF0C4A6E);
  static const Color koiOrange = Color(0xFFEA580C);
  static const Color lotusGreen = Color(0xFF16A34A);

  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryWater,
      primary: primaryWater,
      secondary: koiOrange,
      surface: const Color(0xFFF8FAFC),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepPond,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

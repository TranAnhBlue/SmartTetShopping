import 'package:flutter/material.dart';

class AppTheme {

  /// ===== TẾT COLORS =====
  static const tetRed = Color(0xFFD32F2F);
  static const tetGold = Color(0xFFFFC107);
  static const tetBackground = Color(0xFFFFF5E1);

  // =====================================================
  // ===== LIGHT THEME – TẾT MODE =====
  // =====================================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: tetRed,
      brightness: Brightness.light,
      primary: tetRed,
      secondary: tetGold,
    ),

    scaffoldBackgroundColor: tetBackground,
    fontFamily: 'Roboto',

    // ===== APP BAR =====
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: tetRed,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // ===== CARD =====
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      shadowColor: Colors.red.withOpacity(0.15),
    ),

    // ===== BUTTON =====
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tetRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 2,
      ),
    ),

    // ===== FAB (LÌ XÌ STYLE) =====
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: tetGold,
      foregroundColor: tetRed,
      elevation: 5,
    ),

    // ===== CHIP =====
    chipTheme: ChipThemeData(
      backgroundColor: Colors.red.shade50,
      selectedColor: tetGold,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: tetRed,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // ===== INPUT =====
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: tetGold,
          width: 1.5,
        ),
      ),
    ),

    // ===== LIST TILE =====
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    ),

    // ===== SNACKBAR =====
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tetRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // ===== TEXT =====
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  // =====================================================
  // ===== DARK THEME =====
  // =====================================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: tetRed,
      brightness: Brightness.dark,
    ),

    fontFamily: 'Roboto',

    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
  );
}

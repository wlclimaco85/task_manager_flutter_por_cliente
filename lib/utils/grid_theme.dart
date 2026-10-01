import 'package:flutter/material.dart';
import 'grid_colors.dart';

ThemeData appTheme() {
  const ColorScheme scheme = ColorScheme.light(
    primary: GridColors.primary,
    onPrimary: GridColors.textPrimary,
    primaryContainer: GridColors.primarySoft,
    onPrimaryContainer: GridColors.primaryDark,
    secondary: GridColors.secondary,
    onSecondary: GridColors.textPrimary,
    secondaryContainer: GridColors.secondarySoft,
    onSecondaryContainer: GridColors.secondaryDark,
    error: GridColors.error,
    surface: GridColors.card,
    onSurface: GridColors.textSecondary,
    outline: GridColors.divider,
    shadow: GridColors.shadow,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: GridColors.pageBackground,
    canvasColor: GridColors.pageBackground,
    visualDensity: VisualDensity.standard,
    appBarTheme: const AppBarTheme(
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      centerTitle: false,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: GridColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: GridColors.card,
      selectedItemColor: GridColors.secondary,
      unselectedItemColor: GridColors.textMuted,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 11),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: GridColors.card,
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Colors.white,
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.secondary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: GridColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      labelStyle: const TextStyle(color: GridColors.secondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: GridColors.secondary,
        side: const BorderSide(color: GridColors.secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    dividerColor: GridColors.divider,
    cardColor: GridColors.card,
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: GridColors.secondary,
      contentTextStyle: TextStyle(color: GridColors.textPrimary),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: GridColors.dialogBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

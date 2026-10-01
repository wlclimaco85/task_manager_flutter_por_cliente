import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Tema oficial "Serene Zen Management" para o App Conta Própria.
/// Proporciona sensação de leveza, tranquilidade, clareza e foco anti-ansiedade.
class ZenTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: GridColors.primary,
      scaffoldBackgroundColor: GridColors.background,
      fontFamily: 'Roboto',
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: GridColors.primary,
        onPrimary: Colors.white,
        primaryContainer: GridColors.primarySoft,
        onPrimaryContainer: GridColors.primaryDark,
        secondary: GridColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: GridColors.secondarySoft,
        onSecondaryContainer: GridColors.secondaryDark,
        error: GridColors.error,
        onError: Colors.white,
        errorContainer: GridColors.errorLight,
        onErrorContainer: GridColors.errorDark,
        surface: Colors.white,
        onSurface: GridColors.textPrimary,
        surfaceContainerHighest: GridColors.surfaceMuted,
        onSurfaceVariant: GridColors.textSecondary,
        outline: GridColors.divider,
        outlineVariant: GridColors.borderSubtle,
        shadow: GridColors.shadow,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: GridColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: GridColors.textPrimary),
        titleTextStyle: TextStyle(
          color: GridColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: GridColors.divider, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: GridColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: GridColors.primary,
          side: const BorderSide(color: GridColors.divider, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: GridColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: GridColors.textMuted, fontSize: 14),
        labelStyle: const TextStyle(color: GridColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.divider, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: GridColors.error, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: GridColors.divider,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(GridColors.filterBackground),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return GridColors.selectedRow;
          return Colors.white;
        }),
        headingTextStyle: const TextStyle(
          color: GridColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: const TextStyle(
          color: GridColors.textSecondary,
          fontSize: 13,
        ),
        dividerThickness: 1,
      ),
    );
  }

  /// Decoração de card sereno com sombra difusa e bordas suaves.
  static BoxDecoration zenCardDecoration({
    Color backgroundColor = Colors.white,
    double radius = 16,
    bool withBorder = true,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(radius),
      border: withBorder ? Border.all(color: GridColors.divider, width: 1) : null,
      boxShadow: const [
        BoxShadow(
          color: Color(0x080F172A), // 3-4% opacidade difusa
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}

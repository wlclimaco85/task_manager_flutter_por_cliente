// lib/data/customization/generic_grid/grid_theme.dart
// -----------------------------------------------------------------------------
// 🎨 Tema e Cores padrão do Grid
// -----------------------------------------------------------------------------
import 'package:flutter/material.dart';

class GridColors {
  static const Color primary = Color(0xFF93070A);
  static const Color primaryDark = Color(0xFF6A0507);
  static const Color primarySoft = Color(0xFFFCEDEE);
  static const Color primaryLight = Color(0xFFB84042);
  static const Color secondary = Color(0xFF005826);
  static const Color secondarySoft = Color(0xFFEAF5EE);
  static const Color secondaryLight = Color(0xFF2E7D32);
  static const Color secondaryDark = Color(0xFF003D1A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryMuted = Color(0xB3FFFFFF);
  static const Color textSecondary = Color(0xFF17211B);
  static const Color textMuted = Color(0xFF64756A);
  static const Color background = Color(0xFFF6FAF7);
  static const Color pageBackground = Color(0xFFF6FAF7);
  static const Color surfaceMuted = Color(0xFFF3F7F4);
  static const Color card = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFFFA000);
  static const Color warningDark = Color(0xFFE65100);
  static const Color success = Color(0xFF2E7D32);
  static const Color successDark = Color(0xFF1B5E20);
  static const Color divider = Color(0xFFD8E0DA);
  static const Color borderSubtle = Color(0xFFDDDDDD);
  static const Color shadow = Color(0x26000000);
  static const Color info = Color(0xFF1976D2);
}

// -----------------------------------------------------------------------------
// 🎛️ Estilos de texto (opcional para centralizar padrões de texto do grid)
// -----------------------------------------------------------------------------
class GridTextStyles {
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Colors.black54,
  );

  static const TextStyle value = TextStyle(
    fontSize: 13,
    color: Colors.black87,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
    color: GridColors.textPrimary,
  );

  static const TextStyle title = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: GridColors.primary,
  );
}

// lib/core/theme/mobile_breakpoint_styles.dart
// ─────────────────────────────────────────────────────────────────────────────
// Mobile Breakpoint Styles — 375-599px
//
// Define estilos responsivos específicos para dispositivos móveis
// Tipografia, espaçamento e layout otimizados para telas pequenas
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

class MobileBreakpointStyles {
  MobileBreakpointStyles._();

  // ─────────────────────────────────────────────────────────────────────────────
  // 📱 CONSTANTES DE BREAKPOINT
  // ─────────────────────────────────────────────────────────────────────────────

  static const int minWidth = 375;
  static const int maxWidth = 599;
  static const String name = 'mobile';

  // ─────────────────────────────────────────────────────────────────────────────
  // 📐 LAYOUT E ESPAÇAMENTO
  // ─────────────────────────────────────────────────────────────────────────────

  /// Padding padrão para mobile (menor que tablet/desktop)
  static const double containerPadding = 8.0;

  /// Margin padrão entre elementos
  static const double elementMargin = 8.0;

  /// Espaçamento entre seções
  static const double sectionGap = 16.0;

  /// Número de colunas do grid em mobile
  static const int gridColumns = 4;

  /// Altura padrão de button em mobile
  static const double buttonHeight = 40.0;

  /// Altura padrão de input/text field em mobile
  static const double inputHeight = 40.0;

  /// Borda padrão em mobile
  static const double borderRadius = 4.0;

  // ─────────────────────────────────────────────────────────────────────────────
  // 🔤 TIPOGRAFIA — Escalada para mobile
  // ─────────────────────────────────────────────────────────────────────────────

  /// Logo em mobile (32px, mobile-first)
  static const double logoFontSize = DesignTokens.logoFontSizeMobile;

  /// Heading 1 em mobile (24px)
  static const double h1FontSize = DesignTokens.h1FontSizeMobile;

  /// Heading 2 em mobile (escalado de H1)
  static const double h2FontSize = 20.0;

  /// Heading 3 em mobile
  static const double h3FontSize = 18.0;

  /// Body text em mobile
  static const double bodyFontSize = DesignTokens.bodyFontSize;

  /// Button label em mobile
  static const double buttonFontSize = DesignTokens.buttonLabelFontSize;

  /// Caption/pequeno em mobile
  static const double captionFontSize = DesignTokens.captionFontSize;

  /// Label de form em mobile
  static const double labelFontSize = DesignTokens.labelFontSize;

  // ─────────────────────────────────────────────────────────────────────────────
  // 🎨 CORES — Referência centralizada (DesignTokens)
  // ─────────────────────────────────────────────────────────────────────────────

  static Color get primaryColor => DesignTokens.primary;
  static Color get secondaryColor => DesignTokens.secondary;
  static Color get textPrimary => DesignTokens.textSecondary;
  static Color get textSecondary => DesignTokens.textMuted;
  static Color get backgroundColor => DesignTokens.background;
  static Color get errorColor => DesignTokens.error;
  static Color get successColor => DesignTokens.success;
  static Color get warningColor => DesignTokens.warning;

  // ─────────────────────────────────────────────────────────────────────────────
  // 📦 TEXT STYLES — Pré-configurados para mobile
  // ─────────────────────────────────────────────────────────────────────────────

  static TextStyle get logoStyle => TextStyle(
        fontSize: logoFontSize,
        fontWeight: DesignTokens.logoFontWeight,
        color: textPrimary,
        height: 1.2,
      );

  static TextStyle get h1Style => TextStyle(
        fontSize: h1FontSize,
        fontWeight: DesignTokens.h1FontWeight,
        color: DesignTokens.h1Color,
        height: 1.3,
      );

  static TextStyle get h2Style => TextStyle(
        fontSize: h2FontSize,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        height: 1.3,
      );

  static TextStyle get h3Style => TextStyle(
        fontSize: h3FontSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        height: 1.3,
      );

  static TextStyle get bodyStyle => TextStyle(
        fontSize: bodyFontSize,
        fontWeight: DesignTokens.bodyFontWeight,
        color: textPrimary,
        height: 1.5,
      );

  static TextStyle get buttonStyle => TextStyle(
        fontSize: buttonFontSize,
        fontWeight: DesignTokens.buttonLabelFontWeight,
        color: Colors.white,
        height: 1.2,
      );

  static TextStyle get labelStyle => TextStyle(
        fontSize: labelFontSize,
        fontWeight: DesignTokens.labelFontWeight,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get captionStyle => TextStyle(
        fontSize: captionFontSize,
        fontWeight: DesignTokens.captionFontWeight,
        color: textSecondary,
        height: 1.4,
      );

  static TextStyle get taglineStyle => TextStyle(
        fontSize: DesignTokens.taglineFontSize,
        fontWeight: DesignTokens.taglineFontWeight,
        color: DesignTokens.taglineColor,
        height: 1.4,
      );

  // ─────────────────────────────────────────────────────────────────────────────
  // 🎯 UTILITY METHODS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Verifica se largura está no range mobile (375-599px)
  static bool isInRange(double width) {
    return width >= minWidth && width <= maxWidth;
  }

  /// Retorna padding baseado em tipo de elemento
  static double getPadding(String type) {
    switch (type) {
      case 'container':
        return containerPadding;
      case 'element':
        return elementMargin;
      case 'section':
        return sectionGap;
      default:
        return containerPadding;
    }
  }

  /// Retorna espaçamento entre elementos
  static SizedBox getGap({double? height, double? width}) {
    return SizedBox(
      height: height ?? elementMargin,
      width: width ?? elementMargin,
    );
  }
}

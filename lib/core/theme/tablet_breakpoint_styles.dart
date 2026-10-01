// lib/core/theme/tablet_breakpoint_styles.dart
// ─────────────────────────────────────────────────────────────────────────────
// Tablet Breakpoint Styles — 600-1023px
//
// Define estilos responsivos específicos para tablets e dispositivos intermediários
// Tipografia, espaçamento e layout otimizados para telas médias
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

class TabletBreakpointStyles {
  TabletBreakpointStyles._();

  // ─────────────────────────────────────────────────────────────────────────────
  // 📱 CONSTANTES DE BREAKPOINT
  // ─────────────────────────────────────────────────────────────────────────────

  static const int minWidth = 600;
  static const int maxWidth = 1023;
  static const String name = 'tablet';

  // ─────────────────────────────────────────────────────────────────────────────
  // 📐 LAYOUT E ESPAÇAMENTO
  // ─────────────────────────────────────────────────────────────────────────────

  /// Padding padrão para tablet (intermediário)
  static const double containerPadding = 16.0;

  /// Margin padrão entre elementos
  static const double elementMargin = 16.0;

  /// Espaçamento entre seções (aumentado em relação a mobile)
  static const double sectionGap = 24.0;

  /// Número de colunas do grid em tablet
  static const int gridColumns = 8;

  /// Altura padrão de button em tablet
  static const double buttonHeight = 44.0;

  /// Altura padrão de input/text field em tablet
  static const double inputHeight = 44.0;

  /// Borda padrão em tablet
  static const double borderRadius = 6.0;

  /// Largura máxima de conteúdo em tablet
  static const double maxContentWidth = 800.0;

  // ─────────────────────────────────────────────────────────────────────────────
  // 🔤 TIPOGRAFIA — Escalada para tablet
  // ─────────────────────────────────────────────────────────────────────────────

  /// Logo em tablet (36px, escala intermediária)
  static const double logoFontSize = DesignTokens.logoFontSizeTablet;

  /// Heading 1 em tablet (28px)
  static const double h1FontSize = DesignTokens.h1FontSizeTablet;

  /// Heading 2 em tablet
  static const double h2FontSize = 24.0;

  /// Heading 3 em tablet
  static const double h3FontSize = 20.0;

  /// Body text em tablet (mesmo que mobile, mas com mais espaço)
  static const double bodyFontSize = DesignTokens.bodyFontSize;

  /// Button label em tablet
  static const double buttonFontSize = DesignTokens.buttonLabelFontSize;

  /// Caption/pequeno em tablet
  static const double captionFontSize = DesignTokens.captionFontSize;

  /// Label de form em tablet
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
  // 📦 TEXT STYLES — Pré-configurados para tablet
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

  /// Verifica se largura está no range tablet (600-1023px)
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

  /// Retorna layout helper para limite de conteúdo
  static double getMaxContentWidth(double screenWidth) {
    if (screenWidth < maxContentWidth) {
      return screenWidth - (containerPadding * 2);
    }
    return maxContentWidth;
  }
}

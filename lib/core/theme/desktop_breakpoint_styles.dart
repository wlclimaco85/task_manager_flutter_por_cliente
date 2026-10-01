// lib/core/theme/desktop_breakpoint_styles.dart
// ─────────────────────────────────────────────────────────────────────────────
// Desktop Breakpoint Styles — 1024px+
//
// Define estilos responsivos específicos para desktops e dispositivos grandes
// Tipografia, espaçamento e layout otimizados para telas grandes (web/windows)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../design/design_tokens.dart';

class DesktopBreakpointStyles {
  DesktopBreakpointStyles._();

  // ─────────────────────────────────────────────────────────────────────────────
  // 🖥️  CONSTANTES DE BREAKPOINT
  // ─────────────────────────────────────────────────────────────────────────────

  static const int minWidth = 1024;
  static const int? maxWidth = null; // Sem limite superior
  static const String name = 'desktop';

  // ─────────────────────────────────────────────────────────────────────────────
  // 📐 LAYOUT E ESPAÇAMENTO
  // ─────────────────────────────────────────────────────────────────────────────

  /// Padding padrão para desktop (maior que tablet/mobile)
  static const double containerPadding = 24.0;

  /// Margin padrão entre elementos
  static const double elementMargin = 24.0;

  /// Espaçamento entre seções
  static const double sectionGap = 32.0;

  /// Número de colunas do grid em desktop
  static const int gridColumns = 12;

  /// Altura padrão de button em desktop
  static const double buttonHeight = 48.0;

  /// Altura padrão de input/text field em desktop
  static const double inputHeight = 48.0;

  /// Borda padrão em desktop
  static const double borderRadius = 8.0;

  /// Largura máxima de conteúdo em desktop (container max-width)
  static const double maxContentWidth = 1200.0;

  /// Largura de sidebar em desktop
  static const double sidebarWidth = 320.0;

  /// Largura de sidebar comprimida (collapsed)
  static const double sidebarWidthCollapsed = 80.0;

  // ─────────────────────────────────────────────────────────────────────────────
  // 🔤 TIPOGRAFIA — Escala completa para desktop
  // ─────────────────────────────────────────────────────────────────────────────

  /// Logo em desktop (40px, escala máxima)
  static const double logoFontSize = DesignTokens.logoFontSizeDesktop;

  /// Heading 1 em desktop (28px)
  static const double h1FontSize = DesignTokens.h1FontSizeDesktop;

  /// Heading 2 em desktop
  static const double h2FontSize = 24.0;

  /// Heading 3 em desktop
  static const double h3FontSize = 20.0;

  /// Body text em desktop
  static const double bodyFontSize = DesignTokens.bodyFontSize;

  /// Button label em desktop
  static const double buttonFontSize = DesignTokens.buttonLabelFontSize;

  /// Caption/pequeno em desktop
  static const double captionFontSize = DesignTokens.captionFontSize;

  /// Label de form em desktop
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
  // 📦 TEXT STYLES — Pré-configurados para desktop
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

  /// Verifica se largura está no range desktop (>= 1024px)
  static bool isInRange(double width) {
    return width >= minWidth;
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

  /// Retorna layout helper para limite de conteúdo com margem
  static double getMaxContentWidth(double screenWidth) {
    final double availableWidth = screenWidth - (containerPadding * 2);
    if (availableWidth > maxContentWidth) {
      return maxContentWidth;
    }
    return availableWidth;
  }

  /// Retorna largura de sidebar considerando espaço disponível
  static double getSidebarWidth(bool isCollapsed, double screenWidth) {
    if (isCollapsed) {
      return sidebarWidthCollapsed;
    }
    return sidebarWidth;
  }

  /// Retorna largura do conteúdo principal (descontando sidebar)
  static double getMainContentWidth(double screenWidth, bool sidebarCollapsed) {
    final double sidebarUsed = getSidebarWidth(sidebarCollapsed, screenWidth);
    final double remaining = screenWidth - sidebarUsed - (containerPadding * 2);
    return remaining > 0 ? remaining : screenWidth - (containerPadding * 2);
  }

  /// Retorna altura de header/appbar em desktop
  static double getHeaderHeight() {
    return 64.0;
  }

  /// Retorna altura de footer em desktop
  static double getFooterHeight() {
    return 60.0;
  }
}

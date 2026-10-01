// lib/core/design/design_tokens.dart
// ─────────────────────────────────────────────────────────────────────────────
// 🎨 Design Tokens Consolidados — Sistema de Design Base
//
// Centraliza cores, tipografia responsiva e escala de spacing.
// Reutiliza GridColors existente e adiciona responsividade por breakpoint.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class DesignTokens {
  DesignTokens._();

  // ─────────────────────────────────────────────────────────────────────────────
  // 🎨 CORES (Consolidado de GridColors existente)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Cor primária — Vermelho AppAcademia
  static const Color primary = Color(0xFF93070A);

  /// Variante escura da cor primária
  static const Color primaryDark = Color(0xFF6A0507);

  /// Variante clara/soft da cor primária — para backgrounds
  static const Color primarySoft = Color(0xFFFCEDEE);

  /// Variante light da cor primária — para elementos secundários
  static const Color primaryLight = Color(0xFFB84042);

  /// Cor secundária — Verde AppAcademia
  static const Color secondary = Color(0xFF005826);

  /// Variante soft da cor secundária
  static const Color secondarySoft = Color(0xFFEAF5EE);

  /// Variante light da cor secundária
  static const Color secondaryLight = Color(0xFF2E7D32);

  /// Variante escura da cor secundária
  static const Color secondaryDark = Color(0xFF003D1A);

  /// Texto primário — Branco (usado sobre fundos escuros)
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Texto primário com transparência — para texto secundário sobre fundo escuro
  static const Color textPrimaryMuted = Color(0xB3FFFFFF);

  /// Texto secundário — Preto/Cinza escuro (usado sobre fundos claros)
  static const Color textSecondary = Color(0xFF17211B);

  /// Texto mutado/desabilitado
  static const Color textMuted = Color(0xFF64756A);

  /// Background principal da aplicação
  static const Color background = Color(0xFFF6FAF7);

  /// Background de página
  static const Color pageBackground = Color(0xFFF6FAF7);

  /// Superfície mutada — backgrounds secundários sutis
  static const Color surfaceMuted = Color(0xFFF3F7F4);

  /// Cor de card/superfície elevada
  static const Color card = Color(0xFFFFFFFF);

  /// Cor de erro
  static const Color error = Color(0xFFD32F2F);

  /// Variante light de erro
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Variante dark de erro
  static const Color errorDark = Color(0xFFB71C1C);

  /// Cor de aviso/warning
  static const Color warning = Color(0xFFFFA000);

  /// Variante dark de warning
  static const Color warningDark = Color(0xFFE65100);

  /// Cor de sucesso
  static const Color success = Color(0xFF2E7D32);

  /// Variante dark de sucesso
  static const Color successDark = Color(0xFF1B5E20);

  /// Cor de divisor/linha
  static const Color divider = Color(0xFFD8E0DA);

  /// Cor de borda sutil
  static const Color borderSubtle = Color(0xFFDDDDDD);

  /// Cor de sombra
  static const Color shadow = Color(0x26000000);

  /// Cor de informação
  static const Color info = Color(0xFF1976D2);

  // ─────────────────────────────────────────────────────────────────────────────
  // 🌈 GRADIENTES — Linear Gradients padrão do app
  // ─────────────────────────────────────────────────────────────────────────────

  /// Gradiente primário RED → GREEN (header, card accent)
  static const LinearGradient gradientPrimaryRedGreen = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF93070A), // RED primary
      Color(0xFF005826), // GREEN secondary
    ],
    stops: [0.0, 1.0],
  );

  /// Gradiente suave: primarySoft → secondarySoft
  static const LinearGradient gradientSoft = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFCEDEE), // primarySoft
      Color(0xFFEAF5EE), // secondarySoft
    ],
    stops: [0.0, 1.0],
  );

  /// Gradiente sucesso (para badges/status positivo)
  static const LinearGradient gradientSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2E7D32), // success
      Color(0xFF1B5E20), // successDark
    ],
    stops: [0.0, 1.0],
  );

  // ─────────────────────────────────────────────────────────────────────────────
  // 📏 TIPOGRAFIA RESPONSIVA — Por Breakpoint
  // ─────────────────────────────────────────────────────────────────────────────

  // Logo — Responsivo para 3 breakpoints
  static const double logoFontSizeMobile = 32;
  static const double logoFontSizeTablet = 36;
  static const double logoFontSizeDesktop = 40;
  static const FontWeight logoFontWeight = FontWeight.w600;

  // Heading 1 (H1) — Principal
  static const double h1FontSizeMobile = 24;
  static const double h1FontSizeTablet = 28;
  static const double h1FontSizeDesktop = 28;
  static const FontWeight h1FontWeight = FontWeight.w700;
  static const Color h1Color = Color(0xFF17211B); // textSecondary

  // Tagline — Subtítulo/descrição
  static const double taglineFontSize = 14;
  static const FontWeight taglineFontWeight = FontWeight.w400;
  static const Color taglineColor = Color(0xFF64756A); // textMuted

  // Rótulo de botão/botão
  static const double buttonLabelFontSize = 14;
  static const FontWeight buttonLabelFontWeight = FontWeight.w500;

  // Rótulo de label em formulários
  static const double labelFontSize = 12;
  static const FontWeight labelFontWeight = FontWeight.w500;

  // Tamanho de texto comum/body
  static const double bodyFontSize = 14;
  static const FontWeight bodyFontWeight = FontWeight.w400;

  // Tamanho de caption/pequeno
  static const double captionFontSize = 12;
  static const FontWeight captionFontWeight = FontWeight.w400;

  // ─────────────────────────────────────────────────────────────────────────────
  // 📐 ESCALA DE SPACING — Rigorosa (xs, sm, md, lg, xl, 2xl)
  // ─────────────────────────────────────────────────────────────────────────────

  /// Extra small — 4px
  static const double spacingXs = 4;

  /// Small — 8px
  static const double spacingSm = 8;

  /// Medium — 16px
  static const double spacingMd = 16;

  /// Large — 24px
  static const double spacingLg = 24;

  /// Extra large — 32px
  static const double spacingXl = 32;

  /// 2x Large — 48px
  static const double spacing2xl = 48;

  // ─────────────────────────────────────────────────────────────────────────────
  // 📱 BREAKPOINTS — Confirmados de ResponsiveHelper
  // ─────────────────────────────────────────────────────────────────────────────

  /// Breakpoint móvel: < 768px
  static const int breakpointMobile = 768;

  /// Breakpoint tablet: 768px - 1023px (< 1024px)
  static const int breakpointTablet = 1024;

  /// Breakpoint desktop: >= 1024px
  // Nota: Desktop não tem limite superior fixo; é >= 1024
  static const int breakpointDesktop = 1024;
}

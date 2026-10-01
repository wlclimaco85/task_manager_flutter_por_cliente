import 'package:flutter/material.dart';

/// Design tokens para Manifestação de Recebimento NFe
/// Cores: #93070A (primary), #2E7D32 (success), #D32F2F (error)
/// Tipografia: Roboto 14px body, 24px H1, line-height 1.5
class ManifestacaoDesignTokens {
  // ======== COLORS ========
  static const Color colorPrimary = Color(0xFF93070A); // Vermelho APP
  static const Color colorSuccess = Color(0xFF2E7D32); // Verde
  static const Color colorError = Color(0xFFD32F2F); // Vermelho error
  static const Color colorWarning = Color(0xFFF57C00); // Laranja
  static const Color colorInfo = Color(0xFF1976D2); // Azul
  static const Color colorNeutral50 = Color(0xFFFAFAFA);
  static const Color colorNeutral100 = Color(0xFFF5F5F5);
  static const Color colorNeutral200 = Color(0xFFEEEEEE);
  static const Color colorNeutral300 = Color(0xFFE0E0E0);
  static const Color colorNeutral400 = Color(0xFFBDBDBD);
  static const Color colorNeutral500 = Color(0xFF9E9E9E);
  static const Color colorNeutral600 = Color(0xFF757575);
  static const Color colorNeutral700 = Color(0xFF616161);
  static const Color colorNeutral800 = Color(0xFF424242);
  static const Color colorNeutral900 = Color(0xFF212121);

  // ======== TYPOGRAPHY ========
  static const String fontFamily = 'Roboto';

  // Body text (14px)
  static const TextStyle textBodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: colorNeutral900,
  );

  static const TextStyle textBodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: colorNeutral900,
  );

  static const TextStyle textBodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: colorNeutral900,
  );

  // Headline (24px H1)
  static const TextStyle textHeadline1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: colorNeutral900,
  );

  static const TextStyle textHeadline2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: colorNeutral900,
  );

  // Button text (14px bold)
  static const TextStyle textButton = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.5,
    color: Colors.white,
  );

  // ======== SPACING ========
  static const double spacing2 = 2;
  static const double spacing4 = 4;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;

  // ======== BORDER RADIUS ========
  static const double radiusSmall = 4;
  static const double radiusMedium = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;

  // ======== SHADOWS ========
  static const BoxShadow shadowSmall = BoxShadow(
    color: Colors.black12,
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow shadowMedium = BoxShadow(
    color: Colors.black12,
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow shadowLarge = BoxShadow(
    color: Colors.black12,
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  // ======== BUTTON SIZES ========
  static const double buttonHeightSmall = 36;
  static const double buttonHeightMedium = 44;
  static const double buttonHeightLarge = 52;

  // ======== INPUT SIZES ========
  static const double inputHeightSmall = 36;
  static const double inputHeightMedium = 44;
  static const double inputHeightLarge = 52;

  // ======== BREAKPOINTS (Responsive Design) ========
  static const double breakpointMobile = 768;
  static const double breakpointTablet = 768;
  static const double breakpointDesktop = 1024;

  // ======== TAP TARGET ========
  // WCAG 2.1 AA: Mínimo 48x48dp
  static const double tapTargetMinimum = 48;
}

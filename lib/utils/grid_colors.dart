import 'package:flutter/material.dart';

/// Identidade visual App Conta Própria - Gestão Direta (SaaS B2B).
///
/// Paleta Prumo Contábil (2026-11-12): verde escuro profundo + lima de destaque.
/// - Verde marca (#1F6B4F / #0C3A2B) e lima de acento (#B8E62E).
/// - Fundo cinza-esverdeado claro (#F3F6F4) e superfícies brancas.
/// - Receitas em verde (#2FA36B) e despesas em rosa suave (#D94A5A).
/// - Ausência total de tons fast-food (sem amarelo/laranja/vermelho sangue).
class GridColors {
  // Primária: verde escuro
  static const Color primary = Color(0xFF1F6B4F);
  static const Color primaryDark = Color(0xFF0C3A2B);
  static const Color primaryLight = Color(0xFF4FA07C);
  static const Color primarySoft = Color(0xFFE8F5EE);

  // Secundária: verde-acinzentado
  static const Color secondary = Color(0xFF3F5A4E);
  static const Color secondaryLight = Color(0xFF5F7369);
  static const Color secondarySoft = Color(0xFFEEF3F0);
  static const Color secondaryDark = Color(0xFF2D4338);

  // Acentos & Destaques
  static const Color accent = Color(0xFFB8E62E);
  static const Color accentDark = Color(0xFF0C3A2B);

  // Tipografia & Textos
  static const Color textPrimary = Color(0xFF10241B);
  static const Color textPrimaryMuted = Color(0xFF3F5A4E);
  static const Color textSecondary = Color(0xFF5F7369);
  static const Color textMuted = Color(0xFF93A79C);

  // Links & Controles
  static const Color link = Color(0xFF1F6B4F);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFCBD9D0);
  static const Color buttonBackground = Color(0xFF1F6B4F);
  static const Color buttonText = Color(0xFFFFFFFF);

  // Superfícies & Estrutura
  static const Color background = Color(0xFFF3F6F4);
  static const Color shellBackground = Color(0xFF0C3A2B);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE1E8E3);
  static const Color pageBackground = Color(0xFFF3F6F4);
  static const Color surfaceMuted = Color(0xFFEEF3F0);
  static const Color dialogBackground = Color(0xFFFFFFFF);

  // Status Financeiros & Operacionais Suaves
  static const Color success = Color(0xFF2FA36B);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF059669);

  static const Color error = Color(0xFFC0394B);
  static const Color errorLight = Color(0xFFFFF1F2);
  static const Color errorDark = Color(0xFFBE123C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFFD97706);

  static const Color info = Color(0xFF2F7F9E);

  // Grid & Tabelas
  static const Color filterBackground = Color(0xFFEEF3F0);
  static const Color gridHeader = Color(0xFFEEF3F0);
  static const Color rowEven = Color(0xFFFFFFFF);
  static const Color rowOdd = Color(0xFFF3F6F4);
  static const Color hover = Color(0x0F1F6B4F);
  static const Color selectedRow = Color(0xFFDDEFE5);

  // Elementos Neutros e Bordas
  static const Color neutral = Color(0xFF5F7369);
  static const Color borderSubtle = Color(0xFFE1E8E3);
  static const Color disabledBackground = Color(0xFFE1E8E3);
  static const Color suggestionHigh = Color(0xFFECFDF5);
  static const Color suggestionMedium = Color(0xFFFFFBEB);
  static const Color shadow = Color(0x0A0F172A);

  // Status de Entidades
  static const Color statusHoliday = Color(0xFF2F7F9E);
  static const Color statusClosed = Color(0xFF5F7369);
  static const Color statusNew = Color(0xFF2FA36B);
  static const Color statusUnknown = Color(0xFF93A79C);

  // Cores por tipo de arquivo
  static const Color fileTypePdf = Color(0xFFC0394B);
  static const Color fileTypeImage = Color(0xFF2F7F9E);
  static const Color fileTypeSheet = Color(0xFF2FA36B);
  static const Color fileTypeWord = Color(0xFF3F5A4E);
  static const Color fileTypeDefault = Color(0xFF93A79C);
}

class CustomColors {
  final Color _lightGreenBackground = GridColors.card;
  final Color _darkGreenBorder = GridColors.primary;
  final Color _buttonBackground = GridColors.buttonBackground;
  final Color _textColorDesc = GridColors.textMuted;
  final Color _borderInput = GridColors.inputBorder;
  final Color _textColor = GridColors.textSecondary;
  final Color _negotiationCardBackground = GridColors.card;
  final Color _confirmButtonColor = GridColors.success;
  final Color _cancelButtonColor = GridColors.error;
  final Color _buttonTextColor = GridColors.buttonText;
  final Color _darkBlue = GridColors.shellBackground;
  final Color _headerTable = GridColors.filterBackground;
  final Color _showSnackBarError = GridColors.error;
  final Color _showSnackBarSuccess = GridColors.success;
  final Color _showSnackBarWarning = GridColors.warning;
  final Color _showSnackBarInfo = GridColors.info;
  final Color _showSnackBarText = GridColors.buttonText;

  Color getShowSnackBarText() => _showSnackBarText;
  Color getShowSnackBarInfo() => _showSnackBarInfo;
  Color getShowSnackBarWarning() => _showSnackBarWarning;
  Color getShowSnackBarSuccess() => _showSnackBarSuccess;
  Color getShowSnackBarError() => _showSnackBarError;
  Color getBorderInput() => _borderInput;
  Color getLightGreenBackground() => _lightGreenBackground;
  Color getDarkBlue() => _darkBlue;
  Color getDarkGreenBorder() => _darkGreenBorder;
  Color getButtonBackground() => _buttonBackground;
  Color getTextColorDesc() => _textColorDesc;
  Color getTextColor() => _textColor;
  Color getNegotiationCardBackground() => _negotiationCardBackground;
  Color getConfirmButtonColor() => _confirmButtonColor;
  Color getCancelButtonColor() => _cancelButtonColor;
  Color getButtonTextColor() => _buttonTextColor;
  Color getHeaderTable() => _headerTable;
}

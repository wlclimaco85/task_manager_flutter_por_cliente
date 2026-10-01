import 'package:flutter/material.dart';

/// Identidade visual App Conta Própria - Gestão Direta (SaaS B2B).
///
/// Paleta "Serene Zen Management" (Anti-Ansiedade & Anti-Fome):
/// - Verde Sálvia / Sage (#3E6B5C) e Azul Ardósia (#475569).
/// - Fundo Off-white acolhedor (#F8FAFC) e superfícies limpas (#FFFFFF).
/// - Receitas em Verde Menta/Eucalipto (#10B981) e despesas em Rosa Veludo Atenuado (#E11D48).
/// - Ausência total de tons fast-food (sem amarelo/laranja/vermelho sangue).
class GridColors {
  // Primária: Sage / Sálvia Sereno
  static const Color primary = Color(0xFF3E6B5C);
  static const Color primaryDark = Color(0xFF2D5246);
  static const Color primaryLight = Color(0xFF5C8A7B);
  static const Color primarySoft = Color(0xFFE8EFEA);

  // Secundária: Azul Ardósia Suave
  static const Color secondary = Color(0xFF475569);
  static const Color secondaryLight = Color(0xFF64748B);
  static const Color secondarySoft = Color(0xFFF1F5F9);
  static const Color secondaryDark = Color(0xFF334155);

  // Acentos & Destaques
  static const Color accent = Color(0xFF4E7A6B);
  static const Color accentDark = Color(0xFF2D5246);

  // Tipografia & Textos
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textPrimaryMuted = Color(0xFF475569);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Links & Controles
  static const Color link = Color(0xFF3E6B5C);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color inputBorder = Color(0xFFCBD5E1);
  static const Color buttonBackground = Color(0xFF3E6B5C);
  static const Color buttonText = Color(0xFFFFFFFF);

  // Superfícies & Estrutura
  static const Color background = Color(0xFFF8FAFC);
  static const Color shellBackground = Color(0xFF2D5246);
  static const Color card = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color pageBackground = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color dialogBackground = Color(0xFFFFFFFF);

  // Status Financeiros & Operacionais Suaves
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFECFDF5);
  static const Color successDark = Color(0xFF059669);

  static const Color error = Color(0xFFE11D48);
  static const Color errorLight = Color(0xFFFFF1F2);
  static const Color errorDark = Color(0xFFBE123C);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFFBEB);
  static const Color warningDark = Color(0xFFD97706);

  static const Color info = Color(0xFF0284C7);

  // Grid & Tabelas
  static const Color filterBackground = Color(0xFFF1F5F9);
  static const Color gridHeader = Color(0xFFF1F5F9);
  static const Color rowEven = Color(0xFFFFFFFF);
  static const Color rowOdd = Color(0xFFF8FAFC);
  static const Color hover = Color(0x0F3E6B5C);
  static const Color selectedRow = Color(0xFFE8EFEA);

  // Elementos Neutros e Bordas
  static const Color neutral = Color(0xFF64748B);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color disabledBackground = Color(0xFFE2E8F0);
  static const Color suggestionHigh = Color(0xFFECFDF5);
  static const Color suggestionMedium = Color(0xFFFFFBEB);
  static const Color shadow = Color(0x0A0F172A);

  // Status de Entidades
  static const Color statusHoliday = Color(0xFF0284C7);
  static const Color statusClosed = Color(0xFF64748B);
  static const Color statusNew = Color(0xFF10B981);
  static const Color statusUnknown = Color(0xFF94A3B8);

  // Cores por tipo de arquivo
  static const Color fileTypePdf = Color(0xFFE11D48);
  static const Color fileTypeImage = Color(0xFF0284C7);
  static const Color fileTypeSheet = Color(0xFF10B981);
  static const Color fileTypeWord = Color(0xFF475569);
  static const Color fileTypeDefault = Color(0xFF94A3B8);
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

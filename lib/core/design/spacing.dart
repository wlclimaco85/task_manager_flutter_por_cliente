// lib/core/design/spacing.dart
// ─────────────────────────────────────────────────────────────
// Escala de spacing centralizada — remove valores mágicos
// Padrão: múltiplos de 4 (base) para consistência visual
// ─────────────────────────────────────────────────────────────

class DesignSpacing {
  DesignSpacing._();

  /// Espaçamento extra pequeno: 4px
  static const double xs = 4.0;

  /// Espaçamento pequeno: 8px
  static const double sm = 8.0;

  /// Espaçamento médio: 16px
  static const double md = 16.0;

  /// Espaçamento grande: 24px
  static const double lg = 24.0;

  /// Espaçamento extra grande: 32px
  static const double xl = 32.0;

  /// Espaçamento 2x grande: 48px
  static const double two_xl = 48.0;

  /// Alias semântico: Padding padrão do app
  static const double defaultPadding = md;

  /// Alias semântico: Margin padrão entre elementos
  static const double defaultMargin = lg;

  /// Alias semântico: Espaço entre linhas / componentes
  static const double componentGap = sm;

  /// Alias semântico: Espaço entre seções
  static const double sectionSpacing = two_xl;
}

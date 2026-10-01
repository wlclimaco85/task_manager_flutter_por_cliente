import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';

/// Chip filtrável customizado com remoção
///
/// Exibe ícone + label + opção de remover
/// Adapta-se por breakpoint (padding, font size)
/// Integra com callbacks para remoção
class NfeFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onRemoved;
  final Breakpoint breakpoint;

  const NfeFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onRemoved,
    required this.breakpoint,
  });

  /// Retorna padding responsivo
  EdgeInsets _getPadding() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
      case Breakpoint.tablet:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case Breakpoint.desktop:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    }
  }

  /// Retorna tamanho de ícone responsivo
  double _getIconSize() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 16;
      case Breakpoint.tablet:
        return 18;
      case Breakpoint.desktop:
        return 20;
    }
  }

  /// Retorna tamanho de fonte responsivo
  double _getFontSize() {
    switch (breakpoint) {
      case Breakpoint.mobile:
        return 12;
      case Breakpoint.tablet:
        return 13;
      case Breakpoint.desktop:
        return 14;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: _getIconSize(),
        color: DesignTokens.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: _getFontSize(),
          color: DesignTokens.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: DesignTokens.primarySoft,
      padding: _getPadding(),
      onDeleted: onRemoved,
      deleteIcon: Icon(
        Icons.close,
        size: _getIconSize(),
        color: DesignTokens.primary,
      ),
      side: BorderSide(
        color: DesignTokens.primary.withOpacity(0.3),
        width: 1,
      ),
    );
  }
}

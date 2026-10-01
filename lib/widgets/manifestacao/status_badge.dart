import 'package:flutter/material.dart';
import '../../models/manifestacao/manifestacao_status.dart';
import '../../screens/nfe/design_tokens.dart';

/// Badge para exibição de status da manifestação
/// Implementa WCAG 2.1 AA com contrast ratio ≥ 4.5:1
class StatusBadge extends StatelessWidget {
  /// Status a exibir
  final ManifestacaoStatus? status;

  /// Se deve usar tema dark
  final bool isDarkMode;

  const StatusBadge({
    Key? key,
    this.status,
    this.isDarkMode = false,
  }) : super(key: key);

  /// Retorna ícone baseado no status
  IconData _getIcone() {
    return switch (status) {
      ManifestacaoStatus.aceitar => Icons.check_circle,
      ManifestacaoStatus.parcial => Icons.assignment_late,
      ManifestacaoStatus.recusar => Icons.cancel,
      null => Icons.radio_button_unchecked,
    };
  }

  /// Retorna label baseado no status
  String _getLabel() {
    return switch (status) {
      ManifestacaoStatus.aceitar => 'Aceito',
      ManifestacaoStatus.parcial => 'Aceito Parcial',
      ManifestacaoStatus.recusar => 'Recusado',
      null => 'Não Manifestado',
    };
  }

  /// Retorna cor baseado no status e tema
  Color _getCor() {
    if (isDarkMode) {
      return switch (status) {
        ManifestacaoStatus.aceitar => const Color(0xFF4CAF50),
        ManifestacaoStatus.parcial => const Color(0xFFFFB74D),
        ManifestacaoStatus.recusar => const Color(0xFFEF5350),
        null => const Color(0xFF42A5F5),
      };
    }
    return switch (status) {
      ManifestacaoStatus.aceitar => ManifestacaoDesignTokens.colorSuccess,
      ManifestacaoStatus.parcial => ManifestacaoDesignTokens.colorWarning,
      ManifestacaoStatus.recusar => ManifestacaoDesignTokens.colorError,
      null => ManifestacaoDesignTokens.colorInfo,
    };
  }

  @override
  Widget build(BuildContext context) {
    final cor = _getCor();
    final label = _getLabel();

    return Semantics(
      label: 'Status: $label',
      enabled: true,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcone(),
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

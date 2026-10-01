import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Painel expansível de seção da nota fiscal com indicador de completude.
///
/// Usado no painel lateral de detalhe para organizar campos em seções
/// como Identificação, Tomador, Configuração Fiscal.
class NfSectionPanel extends StatelessWidget {
  final String titulo;
  final IconData icone;
  final bool isComplete;
  final bool initiallyExpanded;
  final List<Widget> children;

  const NfSectionPanel({
    super.key,
    required this.titulo,
    required this.icone,
    required this.children,
    this.isComplete = false,
    this.initiallyExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: GridColors.divider),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icone, size: 18, color: GridColors.primary),
        title: Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: GridColors.textSecondary,
          ),
        ),
        trailing: Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: isComplete ? GridColors.success : GridColors.neutral,
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

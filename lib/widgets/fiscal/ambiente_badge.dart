import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Badge indicando o ambiente da nota fiscal (HOMOLOGACAO ou PRODUCAO).
class AmbienteBadge extends StatelessWidget {
  final String ambiente;

  const AmbienteBadge({super.key, required this.ambiente});

  @override
  Widget build(BuildContext context) {
    final isProducao = ambiente.toUpperCase() == 'PRODUCAO';
    final cor = isProducao ? GridColors.success : Colors.orange.shade700;
    final label = isProducao ? 'PRODUCAO' : 'HOMOLOGACAO';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.15),
        border: Border.all(color: cor),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

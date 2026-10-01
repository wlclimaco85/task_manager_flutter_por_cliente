import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Painel de totais fiscais em tempo real.
///
/// Exibido na base do painel lateral da nota fiscal com
/// valores de bruto, desconto, imposto e líquido.
class NfResumoFiscal extends StatelessWidget {
  final double valorBruto;
  final double desconto;
  final double valorImposto;
  final double valorLiquido;
  final String labelImposto; // 'ISS' ou 'ICMS'

  const NfResumoFiscal({
    super.key,
    required this.valorBruto,
    required this.desconto,
    required this.valorImposto,
    required this.valorLiquido,
    this.labelImposto = 'ISS',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: GridColors.primarySoft,
        border: Border(
          top: BorderSide(color: GridColors.primary.withOpacity(0.25)),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _linha('Valor Bruto', valorBruto),
          if (desconto > 0) _linha('Desconto', -desconto, negativo: true),
          _linha(labelImposto, valorImposto),
          const Divider(height: 12),
          _linha('Valor Líquido', valorLiquido, destaque: true),
        ],
      ),
    );
  }

  Widget _linha(String label, double valor, {bool destaque = false, bool negativo = false}) {
    final cor = negativo
        ? GridColors.error
        : (destaque ? GridColors.primary : GridColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: destaque ? 13 : 12,
              fontWeight: destaque ? FontWeight.w700 : FontWeight.w400,
              color: cor,
            ),
          ),
          Text(
            'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
            style: TextStyle(
              fontSize: destaque ? 14 : 12,
              fontWeight: destaque ? FontWeight.w700 : FontWeight.w500,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

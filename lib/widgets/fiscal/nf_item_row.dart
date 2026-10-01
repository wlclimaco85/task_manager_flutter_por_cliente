import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Linha de item/serviço na tabela da nota fiscal.
///
/// Exibe produto/serviço, quantidade, valor unitário e total.
/// Fundo diferenciado quando selecionada.
class NfItemRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEditar;
  final VoidCallback onRemover;
  final bool isSelected;

  const NfItemRow({
    super.key,
    required this.item,
    required this.onEditar,
    required this.onRemover,
    this.isSelected = false,
  });

  String _texto(String? v) => v?.isNotEmpty == true ? v! : '-';

  String _moeda(dynamic v) {
    final d = double.tryParse(v?.toString() ?? '');
    if (d == null) return '-';
    return 'R\$ ${d.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final produto = item['produto'];
    final nomeProduto = produto is Map
        ? produto['nome']?.toString()
        : item['descricao']?.toString();

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isSelected ? GridColors.primarySoft : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: GridColors.divider, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _texto(nomeProduto),
              style: TextStyle(
                fontSize: 13,
                color: GridColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              _texto(item['quantidade']?.toString()),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: GridColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              _moeda(item['valorUnitario'] ?? item['valor_unitario']),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, color: GridColors.textSecondary),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              _moeda(item['valorTotal'] ?? item['valor_total']),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GridColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16),
            color: GridColors.primary,
            tooltip: 'Editar',
            visualDensity: VisualDensity.compact,
            onPressed: onEditar,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: GridColors.error,
            tooltip: 'Remover',
            visualDensity: VisualDensity.compact,
            onPressed: onRemover,
          ),
        ],
      ),
    );
  }
}

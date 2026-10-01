import 'package:flutter/material.dart';
import 'package:task_manager_flutter/core/design/design_tokens.dart';
import 'package:task_manager_flutter/core/responsive/responsive_helper.dart';
import 'package:task_manager_flutter/models/nfe/nfe_item_model.dart';

/// Tabela/lista de itens de uma NFe com layouts responsivos
///
/// Desktop: DataTable completa
/// Mobile/Tablet: ListView com cards customizados
/// Suporta modo editável com CRUD
class NfeItemsTable extends StatelessWidget {
  final List<NfeItemModel> items;
  final Breakpoint breakpoint;
  final bool editable;
  final Function(int)? onEdit;
  final Function(int)? onDelete;

  const NfeItemsTable({
    super.key,
    required this.items,
    required this.breakpoint,
    this.editable = false,
    this.onEdit,
    this.onDelete,
  });

  /// Formata valor monetário (BRL) com separador de milhares
  /// Exemplo: 1234.56 → "R$ 1.234,56"
  String _formatCurrency(double value) {
    // Converter para string com 2 casas decimais
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    // Adicionar separador de milhares (. em pt_BR) via regex
    // \B(?=(\d{3})+(?!\d)) significa: position nao em word boundary,
    // seguido de múltiplos de 3 dígitos até fim da string
    final formatted = integer.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    // Retornar no formato pt_BR: 1.234,56
    return 'R\$ $formatted,$decimal';
  }

  /// Constrói row para modo mobile/tablet
  Widget _buildRowCard(NfeItemModel item, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.descricao,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${item.codigoProduto}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (editable)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () => onEdit?.call(index),
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: () => onDelete?.call(index),
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: DesignTokens.error),
                            SizedBox(width: 8),
                            Text('Excluir'),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quantidade',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    Text(
                      '${item.quantidade.toStringAsFixed(2)} ${item.unidade}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: DesignTokens.textMuted,
                      ),
                    ),
                    Text(
                      _formatCurrency(item.precoTotal),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: DesignTokens.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.list_alt,
                size: 48,
                color: DesignTokens.textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum item adicionado',
                style: TextStyle(
                  fontSize: 16,
                  color: DesignTokens.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Desktop: DataTable
    if (breakpoint == Breakpoint.desktop) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Descrição')),
            DataColumn(label: Text('Código')),
            DataColumn(label: Text('Qtd'), numeric: true),
            DataColumn(label: Text('Unitário'), numeric: true),
            DataColumn(label: Text('Total'), numeric: true),
            DataColumn(label: Text('Ações')),
          ],
          rows: List.generate(items.length, (index) {
            final item = items[index];
            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 200,
                    child: Text(
                      item.descricao,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(item.codigoProduto)),
                DataCell(Text(item.quantidade.toStringAsFixed(2))),
                DataCell(Text(_formatCurrency(item.precoUnitario))),
                DataCell(Text(_formatCurrency(item.precoTotal))),
                DataCell(
                  editable
                      ? SizedBox(
                          height: 48,
                          child: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                onTap: () => onEdit?.call(index),
                                child: const Row(
                                  children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 8),
                                    Text('Editar'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                onTap: () => onDelete?.call(index),
                                child: const Row(
                                  children: [
                                    Icon(Icons.delete, size: 18, color: DesignTokens.error),
                                    SizedBox(width: 8),
                                    Text('Excluir'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const Text('-'),
                ),
              ],
            );
          }),
        ),
      );
    }

    // Mobile/Tablet: ListView com cards
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildRowCard(items[index], index),
    );
  }
}

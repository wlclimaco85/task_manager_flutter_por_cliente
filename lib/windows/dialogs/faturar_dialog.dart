import 'package:flutter/material.dart';
import '../../../constants/custom_colors.dart';
import '../../../services/pedido_venda_service.dart';
import '../../../utils/grid_texts.dart';

class FaturarDialog extends StatefulWidget {
  final int pedidoId;
  final List<Map<String, dynamic>> itens;
  final VoidCallback onSaved;

  const FaturarDialog({
    super.key,
    required this.pedidoId,
    required this.itens,
    required this.onSaved,
  });

  @override
  State<FaturarDialog> createState() => _FaturarDialogState();
}

class _FaturarDialogState extends State<FaturarDialog> {
  late List<_FaturaItem> _itens;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _itens = widget.itens.map((i) => _FaturaItem(
      itemId: i['id'],
      produtoNome: i['produtoNome'] ?? i['descricao'] ?? '-',
      quantidadeOriginal: (i['quantidade'] as num?)?.toDouble() ?? 0,
      quantidadeFaturar: (i['quantidade'] as num?)?.toDouble() ?? 0,
      valorUnitario: (i['valorUnitario'] as num?)?.toDouble() ?? 0,
      selecionado: true,
    )).toList();
  }

  double get _totalFaturar {
    double total = 0;
    for (final item in _itens) {
      if (item.selecionado) {
        total += item.quantidadeFaturar * item.valorUnitario;
      }
    }
    return total;
  }

  Future<void> _confirmar() async {
    final selected = _itens.where((i) => i.selecionado && i.quantidadeFaturar > 0).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um item'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    final payload = {
      'itens': selected.map((i) => {
        'itemId': i.itemId,
        'quantidade': i.quantidadeFaturar,
      }).toList(),
    };
    final success = await PedidoVendaService.faturarParcial(widget.pedidoId, payload);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao faturar'), backgroundColor: Colors.red),
      );
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: const Text('Faturar Parcial'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: DataTable(
                  columnSpacing: 12,
                  headingRowHeight: 40,
                  dataRowMinHeight: 40,
                  dataRowMaxHeight: 60,
                  columns: const [
                    DataColumn(label: Text('Sel.', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Qtd. Orig.', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Qtd. Faturar', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Valor Unit.', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _itens.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final subtotal = item.quantidadeFaturar * item.valorUnitario;
                    return DataRow(cells: [
                      DataCell(Checkbox(
                        value: item.selecionado,
                        onChanged: (v) => setState(() => item.selecionado = v ?? false),
                      )),
                      DataCell(Text(item.produtoNome)),
                      DataCell(Text(item.quantidadeOriginal.toStringAsFixed(2))),
                      DataCell(SizedBox(
                        width: 80,
                        child: TextFormField(
                          initialValue: item.quantidadeFaturar.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          onChanged: (v) {
                            final qtd = double.tryParse(v) ?? 0;
                            setState(() => item.quantidadeFaturar = qtd.clamp(0, item.quantidadeOriginal));
                          },
                        ),
                      )),
                      DataCell(Text('R\$ ${item.valorUnitario.toStringAsFixed(2)}')),
                      DataCell(Text('R\$ ${subtotal.toStringAsFixed(2)}')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total a Faturar: R\$ ${_totalFaturar.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(GridTexts.cancel),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GridColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Confirmar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaturaItem {
  final int? itemId;
  final String produtoNome;
  final double quantidadeOriginal;
  double quantidadeFaturar;
  final double valorUnitario;
  bool selecionado;

  _FaturaItem({
    this.itemId,
    required this.produtoNome,
    required this.quantidadeOriginal,
    required this.quantidadeFaturar,
    required this.valorUnitario,
    required this.selecionado,
  });
}

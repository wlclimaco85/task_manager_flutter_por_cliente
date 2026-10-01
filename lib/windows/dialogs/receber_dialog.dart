import 'package:flutter/material.dart';
import '../../../constants/custom_colors.dart';
import '../../../services/pedido_compra_service.dart';
import '../../../utils/grid_texts.dart';

class ReceberDialog extends StatefulWidget {
  final int pedidoId;
  final List<Map<String, dynamic>> itens;
  final VoidCallback onSaved;

  const ReceberDialog({
    super.key,
    required this.pedidoId,
    required this.itens,
    required this.onSaved,
  });

  @override
  State<ReceberDialog> createState() => _ReceberDialogState();
}

class _ReceberDialogState extends State<ReceberDialog> {
  late List<_ReceberItem> _itens;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _itens = widget.itens.map((i) => _ReceberItem(
      itemId: i['id'],
      produtoNome: i['produtoNome'] ?? i['descricao'] ?? '-',
      quantidadeOriginal: (i['quantidade'] as num?)?.toDouble() ?? 0,
      quantidadeReceber: (i['quantidade'] as num?)?.toDouble() ?? 0,
      valorUnitario: (i['valorUnitario'] as num?)?.toDouble() ?? 0,
      selecionado: true,
    )).toList();
  }

  double get _totalReceber {
    double total = 0;
    for (final item in _itens) {
      if (item.selecionado) {
        total += item.quantidadeReceber * item.valorUnitario;
      }
    }
    return total;
  }

  Future<void> _confirmar() async {
    final selected = _itens.where((i) => i.selecionado && i.quantidadeReceber > 0).toList();
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
        'quantidade': i.quantidadeReceber,
      }).toList(),
    };
    final success = await PedidoCompraService.receberParcial(widget.pedidoId, payload);
    if (!mounted) return;
    if (success) {
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao receber'), backgroundColor: Colors.red),
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
              title: const Text('Recebimento Parcial'),
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
                    DataColumn(label: Text('Qtd. Pedida', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Qtd. Receber', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Valor Unit.', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: _itens.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;
                    final subtotal = item.quantidadeReceber * item.valorUnitario;
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
                          initialValue: item.quantidadeReceber.toStringAsFixed(2),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          onChanged: (v) {
                            final qtd = double.tryParse(v) ?? 0;
                            setState(() => item.quantidadeReceber = qtd.clamp(0, item.quantidadeOriginal));
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
                    'Total a Receber: R\$ ${_totalReceber.toStringAsFixed(2)}',
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

class _ReceberItem {
  final int? itemId;
  final String produtoNome;
  final double quantidadeOriginal;
  double quantidadeReceber;
  final double valorUnitario;
  bool selecionado;

  _ReceberItem({
    this.itemId,
    required this.produtoNome,
    required this.quantidadeOriginal,
    required this.quantidadeReceber,
    required this.valorUnitario,
    required this.selecionado,
  });
}

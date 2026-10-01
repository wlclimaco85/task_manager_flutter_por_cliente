import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import '../utils/grid_texts.dart';

class NfeXmlPreviewWidget extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool confirming;

  const NfeXmlPreviewWidget({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.confirming = false,
  });

  String? _get(String key) => data[key]?.toString();
  String? _getNested(String outer, String inner) {
    final o = data[outer];
    if (o is Map) return o[inner]?.toString();
    return null;
  }

  bool _chaveExiste() {
    final status = data['status'];
    if (status is String && status.toLowerCase() == 'existente') return true;
    if (data['chaveExistente'] == true) return true;
    if (data['duplicada'] == true) return true;
    return false;
  }

  List<dynamic> _getItens() {
    final itens = data['itens'];
    if (itens is List) return itens;
    if (itens is Map && itens['item'] is List) return itens['item'];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final chave = _get('chave') ?? '-';
    final numero = _get('numero') ?? _get('nNF') ?? '-';
    final serie = _get('serie') ?? '-';
    final chaveExiste = _chaveExiste();
    final emitente = _getNested('emitente', 'xNome') ??
        _getNested('emitente', 'nome') ??
        '-';
    final dhEmi = _get('dhEmi') ?? _get('dataEmissao') ?? '-';
    final vTotal = _get('vNF') ?? _get('vTotal') ?? _get('total') ?? '-';
    final itens = _getItens();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview,
                    color: GridColors.secondary, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Preview da NF-e',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        chaveExiste ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: chaveExiste ? Colors.red : Colors.green,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chaveExiste ? Icons.cancel : Icons.check_circle,
                        size: 16,
                        color: chaveExiste ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        chaveExiste ? 'Chave já existe' : 'Chave nova',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: chaveExiste
                              ? Colors.red.shade800
                              : Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Chave de Acesso', chave),
            _buildField('Número / Série', '$numero / $serie'),
            _buildField('Emitente', emitente),
            _buildField('Data de Emissão', dhEmi),
            _buildField('Valor Total', vTotal),
            if (itens.isNotEmpty) ...[
              const Divider(height: 24),
              const Text(
                'Itens da Nota',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildTabelaItens(itens),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                  ),
                  onPressed: confirming ? null : onConfirm,
                  icon: confirming
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                      confirming ? 'Importando...' : 'Confirmar Importação'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: confirming ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text(GridTexts.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelaItens(List<dynamic> itens) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
            GridColors.secondary.withValues(alpha: 0.1)),
        columnSpacing: 16,
        columns: const [
          DataColumn(
              label: Text('#',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Produto',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('NCM',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('CFOP',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('CST',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Qtde',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('V. Unit.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
          DataColumn(
              label: Text('Total',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
        ],
        rows: itens.asMap().entries.map((entry) {
          final i = entry.value;
          final idx = entry.key + 1;
          return DataRow(cells: [
            DataCell(Text('$idx', style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'xProd') ?? _itemGet(i, 'produto') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'NCM') ?? _itemGet(i, 'ncm') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'CFOP') ?? _itemGet(i, 'cfop') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'CST') ?? _itemGet(i, 'cst') ?? '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(
                _itemGet(i, 'qTrib') ??
                    _itemGet(i, 'qCom') ??
                    _itemGet(i, 'quantidade') ??
                    '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(
                _itemGet(i, 'vUnTrib') ??
                    _itemGet(i, 'vUnCom') ??
                    _itemGet(i, 'valorUnitario') ??
                    '-',
                style: const TextStyle(fontSize: 12))),
            DataCell(Text(_itemGet(i, 'vProd') ?? _itemGet(i, 'total') ?? '-',
                style: const TextStyle(fontSize: 12))),
          ]);
        }).toList(),
      ),
    );
  }

  String? _itemGet(dynamic item, String key) {
    if (item is Map) return item[key]?.toString();
    return null;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: GridColors.secondary,
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

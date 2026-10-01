import 'package:flutter/material.dart';
import '../../../models/orcamento_model.dart';

class OrcamentoHistoricoDialog extends StatelessWidget {
  final List<OrcamentoHistorico> historico;

  const OrcamentoHistoricoDialog({super.key, required this.historico});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          children: [
            AppBar(
              title: const Text('Histórico de Versões'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            if (historico.isEmpty)
              const Expanded(
                child: Center(child: Text('Nenhum histórico disponível')),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: DataTable(
                    columnSpacing: 12,
                    headingRowHeight: 40,
                    dataRowMinHeight: 36,
                    dataRowMaxHeight: 60,
                    columns: const [
                      DataColumn(label: Text('Versão', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status Ant.', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Status Novo', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Observação', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Data', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: historico.map((h) {
                      return DataRow(cells: [
                        DataCell(Text('${h.versao ?? '-'}')),
                        DataCell(Text(h.statusAnterior ?? '-')),
                        DataCell(Text(h.statusNovo ?? '-')),
                        DataCell(Text(h.observacao ?? '-')),
                        DataCell(Text(_formatDate(h.data))),
                      ]);
                    }).toList(),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}

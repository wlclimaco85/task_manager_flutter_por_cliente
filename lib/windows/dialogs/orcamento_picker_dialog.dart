import 'package:flutter/material.dart';

/// Dialog compartilhado (web + windows) para selecionar um orçamento
/// aprovado ao criar um Pedido de Venda a partir de orçamento.
class OrcamentoPickerDialog extends StatelessWidget {
  final List<Map<String, dynamic>> orcamentos;
  const OrcamentoPickerDialog({super.key, required this.orcamentos});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
        child: Column(
          children: [
            AppBar(
              title: const Text('Selecionar Orçamento'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: orcamentos.length,
                itemBuilder: (_, i) {
                  final o = orcamentos[i];
                  return ListTile(
                    title: Text(
                        '${o['numero'] ?? '#'} - ${o['clienteNome'] ?? ''} - R\$ ${(o['totalGeral'] as num?)?.toDouble() ?? 0}'),
                    onTap: () => Navigator.pop(context, o),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

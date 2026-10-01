import 'package:flutter/material.dart';
import '../services/boleto_import_caller.dart';

class ImportacaoBoletosDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  const ImportacaoBoletosDialog({super.key, required this.onSuccess});

  @override
  State<ImportacaoBoletosDialog> createState() => _ImportacaoBoletosDialogState();
}

class _ImportacaoBoletosDialogState extends State<ImportacaoBoletosDialog> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _resultado;

  void _importar() async {
    final linhas = _controller.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (linhas.isEmpty) return;

    setState(() => _loading = true);
    try {
      final boletos = <Map<String, dynamic>>[];
      for (final linha in linhas) {
        final partes = linha.split(';');
        if (partes.length < 3) continue;
        final boleto = <String, dynamic>{
          'cnpjCpf': partes[0].trim(),
          'valor': double.tryParse(partes[1].replaceAll(',', '.')) ?? 0,
          'dataVencimento': partes[2].trim(),
        };
        if (partes.length >= 4 && partes[3].trim().isNotEmpty) {
          boleto['nossoNumero'] = partes[3].trim();
        }
        boletos.add(boleto);
      }
      if (boletos.isEmpty) {
        _snack('Nenhum boleto válido encontrado. Use: CNPJ/CPF;valor;data[;nossoNumero]');
        return;
      }
      final result = await BoletoImportCaller.importar(boletos: boletos);
      final total = result['totalLinhas'] ?? 0;
      final matches = result['matches'] ?? 0;
      final semMatch = result['semMatch'] ?? 0;
      final duplicatas = result['duplicatas'] ?? 0;
      final erros = result['erros'] ?? 0;
      final detalhes = (result['detalhes'] as List?)?.cast<String>() ?? [];

      setState(() => _resultado = 'Total: $total | OK: $matches | Sem parceiro: $semMatch | Duplicatas: $duplicatas | Erros: $erros\n\n${detalhes.join('\n')}');
      if (matches > 0) widget.onSuccess();
    } catch (e) {
      _snack('Erro: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Importar Boletos'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Cole os dados no formato:\nCNPJ/CPF;valor;dataVencimento[;nossoNumero]\n\nExemplo:\n12.345.678/0001-90;1500,00;2026-07-15;1234\n987.654.321-00;890,00;2026-07-20'),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                maxLines: 10,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Cole os dados aqui...',
                ),
              ),
              if (_resultado != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SelectableText(_resultado!, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
        ElevatedButton(
          onPressed: _loading ? null : _importar,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Importar'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../../models/conta_pagar_model.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';

enum TipoRecorrencia { semanal, mensal, anual }

class RecorrenciaContaDialog extends StatefulWidget {
  final ContaPagar conta;

  const RecorrenciaContaDialog({super.key, required this.conta});

  @override
  State<RecorrenciaContaDialog> createState() => _RecorrenciaContaDialogState();
}

class _RecorrenciaContaDialogState extends State<RecorrenciaContaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  TipoRecorrencia _tipo = TipoRecorrencia.mensal;
  final _diaVencimentoController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _diaVencimentoController.text = widget.conta.dataVencimento.day.toString();
  }

  @override
  void dispose() {
    _quantidadeController.dispose();
    _diaVencimentoController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await NetworkCaller().postRequest(
        ApiLinks.contaPagarRecorrencia(widget.conta.id.toString()),
        {
          'tipo': _tipo.name,
          'quantidade': int.parse(_quantidadeController.text),
          'diaVencimento': int.parse(_diaVencimentoController.text),
          'valor': widget.conta.valor,
        },
      );
      if (!mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recorrência gerada com sucesso!')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Recorrência'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Conta: ${widget.conta.descricao}'),
            const SizedBox(height: 16),
            DropdownButtonFormField<TipoRecorrencia>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: TipoRecorrencia.semanal, child: Text('Semanal')),
                DropdownMenuItem(value: TipoRecorrencia.mensal, child: Text('Mensal')),
                DropdownMenuItem(value: TipoRecorrencia.anual, child: Text('Anual')),
              ],
              onChanged: (v) => setState(() => _tipo = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantidadeController,
              decoration: const InputDecoration(
                labelText: 'Quantidade de Repetições',
                prefixIcon: Icon(Icons.repeat),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a quantidade';
                final n = int.tryParse(v);
                if (n == null || n < 1) return 'Mínimo 1 repetição';
                if (n > 360) return 'Máximo 360 repetições';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diaVencimentoController,
              decoration: const InputDecoration(
                labelText: 'Dia de Vencimento',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o dia';
                final n = int.tryParse(v);
                if (n == null || n < 1 || n > 31) return 'Dia inválido (1-31)';
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Gerar Recorrência'),
        ),
      ],
    );
  }
}

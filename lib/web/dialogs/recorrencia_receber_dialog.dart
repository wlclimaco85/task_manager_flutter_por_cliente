import 'package:flutter/material.dart';
import '../../../models/conta_receber_model.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_texts.dart';

enum WebTipoRecorrenciaReceber { semanal, mensal, anual }

class WebRecorrenciaReceberDialog extends StatefulWidget {
  final ContaReceber conta;

  const WebRecorrenciaReceberDialog({super.key, required this.conta});

  @override
  State<WebRecorrenciaReceberDialog> createState() => _WebRecorrenciaReceberDialogState();
}

class _WebRecorrenciaReceberDialogState extends State<WebRecorrenciaReceberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantidadeController = TextEditingController();
  WebTipoRecorrenciaReceber _tipo = WebTipoRecorrenciaReceber.mensal;
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
        ApiLinks.contaReceberRecorrencia(widget.conta.id.toString()),
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
            DropdownButtonFormField<WebTipoRecorrenciaReceber>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: WebTipoRecorrenciaReceber.semanal, child: Text('Semanal')),
                DropdownMenuItem(value: WebTipoRecorrenciaReceber.mensal, child: Text('Mensal')),
                DropdownMenuItem(value: WebTipoRecorrenciaReceber.anual, child: Text('Anual')),
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

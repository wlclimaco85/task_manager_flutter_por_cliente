import 'package:flutter/material.dart';
import '../../../models/conta_pagar_model.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_texts.dart';

class WebParcelarContaDialog extends StatefulWidget {
  final ContaPagar conta;

  const WebParcelarContaDialog({super.key, required this.conta});

  @override
  State<WebParcelarContaDialog> createState() => _WebParcelarContaDialogState();
}

class _WebParcelarContaDialogState extends State<WebParcelarContaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _numeroParcelasController = TextEditingController();
  DateTime _dataPrimeiraParcela = DateTime.now();
  bool _isLoading = false;

  double get _valorParcela {
    final numero = int.tryParse(_numeroParcelasController.text) ?? 1;
    if (numero <= 0) return widget.conta.valor;
    return (widget.conta.valor / numero);
  }

  @override
  void dispose() {
    _numeroParcelasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataPrimeiraParcela,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dataPrimeiraParcela = picked);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final response = await NetworkCaller().postRequest(
        ApiLinks.contaPagarParcelar(widget.conta.id.toString()),
        {
          'numeroParcelas': int.parse(_numeroParcelasController.text),
          'dataPrimeiraParcela': _dataPrimeiraParcela.toIso8601String(),
          'valorParcela': _valorParcela,
        },
      );
      if (!mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Parcelamento realizado com sucesso!')),
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
      title: const Text('Parcelar Conta'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Conta: ${widget.conta.descricao}'),
            Text('Valor total: R\$ ${widget.conta.valor.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroParcelasController,
              decoration: const InputDecoration(
                labelText: 'Número de Parcelas',
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe o número de parcelas';
                final n = int.tryParse(v);
                if (n == null || n < 2) return 'Mínimo de 2 parcelas';
                if (n > 120) return 'Máximo de 120 parcelas';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 8),
                const Text('1ª Parcela:'),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _selectDate,
                  child: Text(
                    '${_dataPrimeiraParcela.day}/${_dataPrimeiraParcela.month}/${_dataPrimeiraParcela.year}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_numeroParcelasController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_numeroParcelasController.text}x de R\$ ${_valorParcela.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
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
              : const Text('Confirmar Parcelamento'),
        ),
      ],
    );
  }
}

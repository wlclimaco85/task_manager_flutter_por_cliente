import 'package:flutter/material.dart';
import '../../../models/conta_pagar_model.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_texts.dart';

class RenegociacaoContaDialog extends StatefulWidget {
  final ContaPagar conta;

  const RenegociacaoContaDialog({super.key, required this.conta});

  @override
  State<RenegociacaoContaDialog> createState() => _RenegociacaoContaDialogState();
}

class _RenegociacaoContaDialogState extends State<RenegociacaoContaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _novoValorController = TextEditingController();
  final _jurosController = TextEditingController();
  final _multaController = TextEditingController();
  final _descontoController = TextEditingController();
  final _observacaoController = TextEditingController();
  final _numeroParcelasController = TextEditingController();
  DateTime _novaDataVencimento = DateTime.now();
  bool _gerarParcelas = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _novoValorController.text = widget.conta.valor.toStringAsFixed(2);
    _novaDataVencimento = widget.conta.dataVencimento;
    _numeroParcelasController.text = '1';
  }

  @override
  void dispose() {
    _novoValorController.dispose();
    _jurosController.dispose();
    _multaController.dispose();
    _descontoController.dispose();
    _observacaoController.dispose();
    _numeroParcelasController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _novaDataVencimento,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _novaDataVencimento = picked);
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final body = <String, dynamic>{
        'novoValor': double.parse(_novoValorController.text),
        'novaDataVencimento': _novaDataVencimento.toIso8601String(),
        'observacao': _observacaoController.text,
      };
      if (_jurosController.text.isNotEmpty) body['juros'] = double.parse(_jurosController.text);
      if (_multaController.text.isNotEmpty) body['multa'] = double.parse(_multaController.text);
      if (_descontoController.text.isNotEmpty) body['desconto'] = double.parse(_descontoController.text);
      if (_gerarParcelas) {
        body['gerarParcelas'] = true;
        body['numeroParcelas'] = int.parse(_numeroParcelasController.text);
      }

      final response = await NetworkCaller().postRequest(
        ApiLinks.contaPagarRenegociar(widget.conta.id.toString()),
        body,
      );
      if (!mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renegociação realizada com sucesso!')),
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
      title: const Text('Renegociar Conta'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Conta: ${widget.conta.descricao}'),
              Text('Valor atual: R\$ ${widget.conta.valor.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _novoValorController,
                decoration: const InputDecoration(
                  labelText: 'Novo Valor',
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe o novo valor';
                  if (double.tryParse(v) == null) return 'Valor inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  const Text('Nova Data:'),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _selectDate,
                    child: Text(
                      '${_novaDataVencimento.day}/${_novaDataVencimento.month}/${_novaDataVencimento.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _jurosController,
                decoration: const InputDecoration(
                  labelText: 'Juros (%)',
                  prefixIcon: Icon(Icons.trending_up),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _multaController,
                decoration: const InputDecoration(
                  labelText: 'Multa (%)',
                  prefixIcon: Icon(Icons.warning),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descontoController,
                decoration: const InputDecoration(
                  labelText: 'Desconto (%)',
                  prefixIcon: Icon(Icons.discount),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Gerar Parcelas'),
                value: _gerarParcelas,
                onChanged: (v) => setState(() => _gerarParcelas = v!),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (_gerarParcelas)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextFormField(
                    controller: _numeroParcelasController,
                    decoration: const InputDecoration(
                      labelText: 'Número de Parcelas',
                      prefixIcon: Icon(Icons.numbers),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (!_gerarParcelas) return null;
                      if (v == null || v.isEmpty) return 'Informe as parcelas';
                      if (int.tryParse(v) == null || int.parse(v) < 2) return 'Mínimo 2 parcelas';
                      return null;
                    },
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _observacaoController,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
            ],
          ),
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
              : const Text('Confirmar Renegociação'),
        ),
      ],
    );
  }
}

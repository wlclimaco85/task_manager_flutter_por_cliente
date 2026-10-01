import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/conta_bancaria_model.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';

typedef AjusteSaldoContaSubmit = Future<bool> Function({
  double? saldoInicial,
  double? saldoFinal,
});

class AjusteSaldoContaDialog extends StatefulWidget {
  final ContaBancaria conta;
  final AjusteSaldoContaSubmit onSalvar;

  const AjusteSaldoContaDialog({
    super.key,
    required this.conta,
    required this.onSalvar,
  });

  @override
  State<AjusteSaldoContaDialog> createState() => _AjusteSaldoContaDialogState();
}

class _AjusteSaldoContaDialogState extends State<AjusteSaldoContaDialog> {
  final TextEditingController _saldoInicialController = TextEditingController();
  final TextEditingController _saldoFinalController = TextEditingController();
  bool _salvando = false;
  String? _erro;

  bool get _temSaldoInicial => _saldoInicialController.text.trim().isNotEmpty;

  bool get _temSaldoFinal => _saldoFinalController.text.trim().isNotEmpty;

  bool get _podeSalvar => _temSaldoInicial != _temSaldoFinal && !_salvando;

  @override
  void dispose() {
    _saldoInicialController.dispose();
    _saldoFinalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GridColors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: GridColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Ajustar saldo da conta',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed:
                        _salvando ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _contaLabel(widget.conta),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: GridColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Escolha saldo inicial ou saldo final. Ao preencher um campo, o outro fica bloqueado.',
                    style: const TextStyle(color: GridColors.textMuted),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('ajuste_saldo_inicial_field'),
                    controller: _saldoInicialController,
                    enabled: !_temSaldoFinal && !_salvando,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() => _erro = null),
                    decoration: _decoration(
                      label: 'Saldo inicial',
                      helper:
                          'Recalcula o saldo atual somando os movimentos existentes.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    key: const Key('ajuste_saldo_final_field'),
                    controller: _saldoFinalController,
                    enabled: !_temSaldoInicial && !_salvando,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() => _erro = null),
                    decoration: _decoration(
                      label: 'Saldo final',
                      helper: 'Define o saldo atual da conta diretamente.',
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _erro!,
                      style: const TextStyle(color: GridColors.error),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _salvando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    key: const Key('ajuste_saldo_salvar_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.secondary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: GridColors.disabledBackground,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    onPressed: _podeSalvar ? _salvar : null,
                    icon: _salvando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_salvando ? 'Salvando...' : 'Salvar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    required String helper,
  }) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      prefixText: 'R\$ ',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: GridColors.secondary, width: 2),
      ),
    );
  }

  Future<void> _salvar() async {
    final saldoInicial = _parseValor(_saldoInicialController.text);
    final saldoFinal = _parseValor(_saldoFinalController.text);
    if ((saldoInicial == null && saldoFinal == null) ||
        (saldoInicial != null && saldoFinal != null)) {
      setState(() => _erro = 'Informe apenas um dos saldos.');
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    final sucesso = await widget.onSalvar(
      saldoInicial: saldoInicial,
      saldoFinal: saldoFinal,
    );

    if (!mounted) return;
    if (sucesso) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _salvando = false;
      _erro = 'Nao foi possivel ajustar o saldo.';
    });
  }

  double? _parseValor(String value) {
    final normalized = value.trim().replaceAll('.', '').replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  String _contaLabel(ContaBancaria conta) {
    final partes = [conta.banco, conta.agencia, conta.numero, conta.descricao]
        .where((item) => item != null && item.trim().isNotEmpty)
        .map((item) => item!.trim())
        .toList();
    return partes.isEmpty ? 'Conta bancaria' : partes.join(' - ');
  }
}

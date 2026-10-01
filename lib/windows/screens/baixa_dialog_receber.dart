import 'package:flutter/material.dart';
import '../../../models/conta_receber_model.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

/// Popup "Registrar Baixa" de Conta a Receber (Windows/Mobile).
/// Funcional: posta em [ApiLinks.registrarBaixaContaReceber] e retorna
/// `true` via Navigator.pop quando a baixa é confirmada com sucesso.
class BaixaDialogReceber extends StatefulWidget {
  final ContaReceber conta;

  const BaixaDialogReceber({super.key, required this.conta});

  @override
  State<BaixaDialogReceber> createState() => _BaixaDialogReceberState();
}

class _BaixaDialogReceberState extends State<BaixaDialogReceber> {
  final _formKey = GlobalKey<FormState>();
  final _valorBaixaController = TextEditingController();
  final _valorMultaController = TextEditingController();
  final _valorJurosController = TextEditingController();
  final _valorDescontoController = TextEditingController();

  DateTime _dataBaixa = DateTime.now();
  int? _contaId;
  int? _formaPagamentoId;
  bool _isLoading = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _contas = [];
  List<FormaPagamento> _formasPagamento = [];

  @override
  void initState() {
    super.initState();
    _valorBaixaController.text = widget.conta.valor.toStringAsFixed(2);
    _valorMultaController.text =
        widget.conta.valorMulta?.toStringAsFixed(2) ?? '0.00';
    _valorJurosController.text =
        widget.conta.valorJuros?.toStringAsFixed(2) ?? '0.00';
    _valorDescontoController.text =
        widget.conta.valorDesconto?.toStringAsFixed(2) ?? '0.00';
    _loadData();
  }

  Future<void> _loadData() async {
    final contas = await ContaBancariaCaller.loadContas();
    final formasMap = await FormaPagamento.loadFormasPagamento();
    if (!mounted) return;
    setState(() {
      _contas = contas;
      _formasPagamento = formasMap
          .map((m) => FormaPagamento(
                id: m['value'],
                nome: m['label'],
                descricao: '',
                status: 'Ativo',
                audit: null,
              ))
          .toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: GridColors.dialogBackground,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BaixaReceberHeader(
              onClose: _isSaving ? null : () => Navigator.pop(context),
            ),
            Flexible(
              child: _isLoading
                  ? const SizedBox(
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: GridColors.primary,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ContaResumo(conta: widget.conta),
                            const SizedBox(height: 20),
                            _campoLabel('Valor da baixa'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _valorBaixaController,
                              decoration: _inputDecoration(
                                hint: '0,00',
                                icon: Icons.attach_money,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Informe o valor';
                                }
                                final val =
                                    double.tryParse(v.replaceAll(',', '.'));
                                if (val == null || val <= 0) {
                                  return 'Valor inválido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _campoLabel('Multa'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _valorMultaController,
                                        decoration: _inputDecoration(
                                          hint: '0,00',
                                          icon: Icons.gavel_outlined,
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _campoLabel('Juros'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _valorJurosController,
                                        decoration: _inputDecoration(
                                          hint: '0,00',
                                          icon: Icons.trending_up,
                                        ),
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _campoLabel('Desconto'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _valorDescontoController,
                              decoration: _inputDecoration(
                                hint: '0,00',
                                icon: Icons.sell_outlined,
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                            const SizedBox(height: 16),
                            _campoLabel('Forma de pagamento'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              decoration: _inputDecoration(
                                hint: 'Selecione',
                                icon: Icons.payment,
                              ),
                              initialValue: _formaPagamentoId,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: GridColors.neutral),
                              items: _formasPagamento
                                  .map((f) => DropdownMenuItem<int>(
                                      value: f.id, child: Text(f.nome ?? '')))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _formaPagamentoId = v),
                              validator: (v) => v == null
                                  ? 'Selecione a forma de pagamento'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _campoLabel('Conta bancária'),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<int>(
                              decoration: _inputDecoration(
                                hint: 'Selecione',
                                icon: Icons.account_balance,
                              ),
                              initialValue: _contaId,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: GridColors.neutral),
                              items: _contas
                                  .map<DropdownMenuItem<int>>(
                                    (c) => DropdownMenuItem<int>(
                                      value: c['value'] as int,
                                      child: Text(c['label'],
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _contaId = v),
                              validator: (v) => v == null
                                  ? 'Selecione a conta bancária'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _campoLabel('Data da baixa'),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () => _pickDate(context),
                              borderRadius: BorderRadius.circular(10),
                              child: InputDecorator(
                                decoration: _inputDecoration(
                                  icon: Icons.calendar_today,
                                ),
                                child: Text(
                                  '${_dataBaixa.day.toString().padLeft(2, '0')}/'
                                  '${_dataBaixa.month.toString().padLeft(2, '0')}/'
                                  '${_dataBaixa.year}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: GridColors.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            _BaixaReceberFooter(
              isBusy: _isLoading || _isSaving,
              isSaving: _isSaving,
              onCancel: _isSaving ? null : () => Navigator.pop(context),
              onConfirm: (_isLoading || _isSaving) ? null : _baixar,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: GridColors.primary,
            onPrimary: Colors.white,
            onSurface: GridColors.textSecondary,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null && mounted) setState(() => _dataBaixa = d);
  }

  Future<void> _baixar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final valorBaixa =
        double.tryParse(_valorBaixaController.text.replaceAll(',', '.')) ?? 0;
    final valorMulta =
        double.tryParse(_valorMultaController.text.replaceAll(',', '.')) ?? 0;
    final valorJuros =
        double.tryParse(_valorJurosController.text.replaceAll(',', '.')) ?? 0;
    final valorDesconto =
        double.tryParse(_valorDescontoController.text.replaceAll(',', '.')) ?? 0;

    final NetworkResponse response = await NetworkCaller().postRequest(
      ApiLinks.registrarBaixaContaReceber(widget.conta.id.toString()),
      {
        'dataBaixa': _dataBaixa.toIso8601String(),
        'valorBaixa': valorBaixa,
        'valorMulta': valorMulta,
        'valorJuros': valorJuros,
        'valorDesconto': valorDesconto,
        'formaPagamentoId': _formaPagamentoId,
        'contaId': _contaId,
      },
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(response.isSuccess
          ? 'Baixa registrada com sucesso!'
          : 'Erro ao registrar baixa: ${response.statusCode}'),
      backgroundColor:
          response.isSuccess ? GridColors.success : GridColors.error,
    ));

    if (response.isSuccess) Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _valorBaixaController.dispose();
    _valorMultaController.dispose();
    _valorJurosController.dispose();
    _valorDescontoController.dispose();
    super.dispose();
  }
}

/// Rótulo padrão dos campos do formulário de baixa.
Widget _campoLabel(String text) => Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: GridColors.textSecondary,
      ),
    );

/// Decoração consistente para inputs e dropdowns do formulário.
InputDecoration _inputDecoration({String? hint, IconData? icon}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: GridColors.neutral, fontSize: 14),
    isDense: true,
    filled: true,
    fillColor: GridColors.inputBackground,
    prefixIcon:
        icon == null ? null : Icon(icon, size: 20, color: GridColors.neutral),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: GridColors.borderSubtle),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: GridColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: GridColors.error, width: 1.5),
    ),
  );
}

/// Cabeçalho vermelho com identidade AppAcademia.
class _BaixaReceberHeader extends StatelessWidget {
  final VoidCallback? onClose;

  const _BaixaReceberHeader({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [GridColors.primary, GridColors.primaryDark],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.download_done_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registrar Baixa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Conta a Receber',
                  style: TextStyle(
                    color: GridColors.textPrimaryMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: 'Fechar',
              splashRadius: 20,
            ),
        ],
      ),
    );
  }
}

/// Cartão de resumo com descrição e valor original em destaque.
class _ContaResumo extends StatelessWidget {
  final ContaReceber conta;

  const _ContaResumo({required this.conta});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conta.descricao,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: GridColors.textSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Text(
            'VALOR ORIGINAL',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: GridColors.neutral,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'R\$ ${conta.valor.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: GridColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rodapé com ações Cancelar / Confirmar Baixa.
class _BaixaReceberFooter extends StatelessWidget {
  final bool isBusy;
  final bool isSaving;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  const _BaixaReceberFooter({
    required this.isBusy,
    required this.isSaving,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GridColors.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: GridColors.neutral,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Text(GridTexts.cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  GridColors.primary.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 20),
            label: Text(isSaving ? 'Registrando...' : 'Confirmar Baixa'),
          ),
        ],
      ),
    );
  }
}

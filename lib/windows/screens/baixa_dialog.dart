// baixa_dialog.dart
import 'package:flutter/material.dart';
import '../../../models/conta_pagar_model.dart';
import '../../../models/forma_pagamento_model.dart';
import '../../services/conta_bancaria_caller.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';
import '../../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class BaixaDialog extends StatefulWidget {
  final ContaPagar conta;

  const BaixaDialog({super.key, required this.conta});

  @override
  _BaixaDialogState createState() => _BaixaDialogState();
}

class _BaixaDialogState extends State<BaixaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  DateTime _dataBaixa = DateTime.now();
  int? _formaPagamentoId;
  int? _contaId;
  bool _isLoading = true;
  bool _isSubmitting = false;
  List<FormaPagamento> _formasPagamento = [];
  List<Map<String, dynamic>> _contas = [];

  @override
  void initState() {
    super.initState();
    _valorController.text = widget.conta.valor.toString();
    _loadDados();
  }

  Future<void> _loadDados() async {
    final formasMap = await FormaPagamento.loadFormasPagamento();
    final contas = await ContaBancariaCaller.loadContas();

    final List<FormaPagamento> formas = formasMap
        .map(
          (map) => FormaPagamento(
            id: map['value'],
            nome: map['label'],
            descricao: '',
            status: 'Ativo',
            audit: null,
          ),
        )
        .toList();
    if (!mounted) return;
    setState(() {
      _formasPagamento = formas;
      _contas = contas;
      _isLoading = false;
    });
  }

  String get _dataBaixaFormatted =>
      '${_dataBaixa.day.toString().padLeft(2, '0')}/'
      '${_dataBaixa.month.toString().padLeft(2, '0')}/'
      '${_dataBaixa.year}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: SizedBox(
        width: 420,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: GridColors.dialogBackground,
            elevation: 8,
            shadowColor: GridColors.shadow,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildBody(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.payments_outlined,
              color: GridColors.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  GridTexts.registerLow,
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                if (widget.conta.descricao.isNotEmpty)
                  Text(
                    widget.conta.descricao,
                    style: const TextStyle(
                      color: GridColors.textPrimaryMuted,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: GridColors.textPrimaryMuted, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            tooltip: GridTexts.cancel,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Campo Valor da Baixa
            TextFormField(
              controller: _valorController,
              decoration: InputDecoration(
                labelText: GridTexts.lowValue,
                prefixIcon: const Icon(Icons.attach_money, size: 20),
                prefixIconColor: GridColors.primary,
                floatingLabelStyle: const TextStyle(color: GridColors.primary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: GridColors.borderSubtle),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: GridColors.error),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: GridColors.error, width: 1.5),
                ),
                filled: true,
                fillColor: GridColors.inputBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return GridTexts.enterLowValue;
                }
                final valor = double.tryParse(value);
                if (valor == null || valor <= 0) {
                  return GridTexts.valueMustBeGreaterThanZero;
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Dropdown Formas de Pagamento
            _isLoading
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: GridColors.inputBackground,
                      border: Border.all(color: GridColors.borderSubtle),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GridColors.primary,
                        ),
                      ),
                    ),
                  )
                : DropdownButtonFormField<int>(
                    value: _formaPagamentoId,
                    decoration: InputDecoration(
                      labelText: GridTexts.paymentMethod,
                      prefixIcon: const Icon(Icons.payment, size: 20),
                      prefixIconColor: GridColors.primary,
                      floatingLabelStyle: const TextStyle(color: GridColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.error, width: 1.5),
                      ),
                      filled: true,
                      fillColor: GridColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    isExpanded: true,
                    items: _formasPagamento.map((forma) {
                      return DropdownMenuItem<int>(
                        value: forma.id,
                        child: Text(
                          forma.nome ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _formaPagamentoId = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return GridTexts.selectPaymentMethod;
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 14),

            // Dropdown Conta Bancária
            _isLoading
                ? Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: GridColors.inputBackground,
                      border: Border.all(color: GridColors.borderSubtle),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GridColors.primary,
                        ),
                      ),
                    ),
                  )
                : DropdownButtonFormField<int>(
                    initialValue: _contaId,
                    decoration: InputDecoration(
                      labelText: 'Conta Bancária',
                      prefixIcon: const Icon(Icons.account_balance, size: 20),
                      prefixIconColor: GridColors.primary,
                      floatingLabelStyle: const TextStyle(color: GridColors.primary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.borderSubtle),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.primary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: GridColors.error, width: 1.5),
                      ),
                      filled: true,
                      fillColor: GridColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    isExpanded: true,
                    items: _contas
                        .map<DropdownMenuItem<int>>(
                          (c) => DropdownMenuItem<int>(
                            value: c['value'] as int,
                            child: Text(c['label'], overflow: TextOverflow.ellipsis),
                          ),
                        )
                        .toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _contaId = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione a conta bancária';
                      }
                      return null;
                    },
                  ),
            const SizedBox(height: 14),

            // Campo Data da Baixa (estilo InputDecoration completo)
            InkWell(
              onTap: () => _selectDate(context),
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: GridTexts.lowDate,
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  prefixIconColor: GridColors.primary,
                  suffixIcon: const Icon(Icons.arrow_drop_down, color: GridColors.primary),
                  floatingLabelStyle: const TextStyle(color: GridColors.primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: GridColors.borderSubtle),
                  ),
                  filled: true,
                  fillColor: GridColors.inputBackground,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                child: Text(
                  _dataBaixaFormatted,
                  style: const TextStyle(
                    fontSize: 14,
                    color: GridColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: GridColors.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: GridColors.textMuted,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(GridTexts.cancel),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitBaixa,
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.success,
              foregroundColor: GridColors.textPrimary,
              disabledBackgroundColor: GridColors.disabledBackground,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            icon: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: GridColors.textPrimary,
                    ),
                  )
                : const Icon(Icons.check_circle_outline, size: 18),
            label: Text(
              _isSubmitting ? GridTexts.saving : GridTexts.confirmLow,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: GridColors.primary,
              onPrimary: GridColors.textPrimary,
              surface: GridColors.dialogBackground,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dataBaixa) {
      setState(() {
        _dataBaixa = picked;
      });
    }
  }

  void _submitBaixa() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final valorBaixa = double.parse(_valorController.text);

      final NetworkResponse response = await NetworkCaller().postRequest(
        ApiLinks.registrarBaixaContaPagar(widget.conta.id.toString()),
        {
          'dataBaixa': _dataBaixa.toIso8601String(),
          'valorBaixa': valorBaixa,
          'formaPagamentoId': _formaPagamentoId,
          'contaId': _contaId,
        },
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (response.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(GridTexts.lowRegisteredSuccess)),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              GridTexts.lowRegisterError(response.statusCode),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }
}

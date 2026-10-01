// lib/web/dialogs/baixa_lote_dialog.dart
import 'package:flutter/material.dart';
import '../../models/baixa_lote_model.dart';
import '../../models/conta_bancaria_model.dart';
import '../../models/forma_pagamento_model.dart';
import '../../services/baixa_lote_service.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

/// Dialog for batch baixa (bulk payment) of multiple contas.
///
/// Supports both pagar and receber modes via [isPagar] flag.
/// [selectedIds] are the IDs of the contas to baixa.
/// [selectedContas] are the full objects (used to show descriptions/values).
class BaixaLoteDialog extends StatefulWidget {
  final bool isPagar;
  final List<int> selectedIds;
  final List<Map<String, dynamic>> selectedContas;

  const BaixaLoteDialog({
    super.key,
    required this.isPagar,
    required this.selectedIds,
    required this.selectedContas,
  });

  @override
  State<BaixaLoteDialog> createState() => _BaixaLoteDialogState();
}

class _BaixaLoteDialogState extends State<BaixaLoteDialog> {
  final _formKey = GlobalKey<FormState>();
  DateTime _dataBaixa = DateTime.now();
  int? _formaPagamentoId;
  int? _contaBancariaId;
  final _observacaoController = TextEditingController();

  bool _isLoadingFormas = true;
  bool _isLoadingContas = true;
  bool _isSubmitting = false;

  List<FormaPagamento> _formasPagamento = [];
  List<ContaBancaria> _contasBancarias = [];

  // Per-item overrides: index -> {juros, multa, desconto}
  final Map<int, Map<String, TextEditingController>> _itemControllers = {};

  // Results after submission
  BaixaLoteResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadFormasPagamento();
    _loadContasBancarias();
    _initItemControllers();
  }

  void _initItemControllers() {
    for (int i = 0; i < widget.selectedContas.length; i++) {
      _itemControllers[i] = {
        'juros': TextEditingController(text: '0'),
        'multa': TextEditingController(text: '0'),
        'desconto': TextEditingController(text: '0'),
      };
    }
  }

  Future<void> _loadFormasPagamento() async {
    final List<Map<String, dynamic>> formasMap =
        await FormaPagamento.loadFormasPagamento();
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
    if (mounted) setState(() { _formasPagamento = formas; _isLoadingFormas = false; });
  }

  Future<void> _loadContasBancarias() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allContasBancarias);
    if (response.isSuccess && response.body != null) {
      final data = response.body!;
      final list = (data['data']?['dados'] ?? data['data'] ?? []) as List;
      final contas = list.map((e) => ContaBancaria.fromJson(e)).toList();
      if (mounted) setState(() { _contasBancarias = contas; _isLoadingContas = false; });
    } else {
      if (mounted) setState(() => _isLoadingContas = false);
    }
  }

  @override
  void dispose() {
    _observacaoController.dispose();
    for (final controllers in _itemControllers.values) {
      for (final c in controllers.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_response != null) return _buildResultView();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: GridColors.secondary,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Baixa em Lote (${widget.isPagar ? 'Pagar' : 'Receber'})',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GridColors.textSecondary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(color: GridColors.divider),
                const SizedBox(height: 8),

                Text(
                  '${widget.selectedIds.length} conta(s) selecionada(s)',
                  style: const TextStyle(
                    fontSize: 13,
                    color: GridColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Form Fields ──
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Data Baixa
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18,
                                color: GridColors.textMuted),
                            const SizedBox(width: 8),
                            const Text('Data da Baixa:',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: _selectDate,
                              child: Text(
                                '${_dataBaixa.day}/${_dataBaixa.month}/${_dataBaixa.year}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Forma Pagamento
                        _isLoadingFormas
                            ? const SizedBox(
                                height: 40,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : DropdownButtonFormField<int>(
                                value: _formaPagamentoId,
                                decoration: const InputDecoration(
                                  labelText: 'Forma de Pagamento',
                                  prefixIcon: Icon(Icons.payment),
                                  border: OutlineInputBorder(),
                                ),
                                items: _formasPagamento.map((forma) {
                                  return DropdownMenuItem<int>(
                                    value: forma.id,
                                    child: Text(forma.nome ?? ''),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _formaPagamentoId = v),
                                validator: (v) =>
                                    v == null ? 'Selecione a forma de pagamento' : null,
                              ),
                        const SizedBox(height: 12),

                        // Conta Bancaria
                        _isLoadingContas
                            ? const SizedBox(
                                height: 40,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : DropdownButtonFormField<int>(
                                value: _contaBancariaId,
                                decoration: const InputDecoration(
                                  labelText: 'Conta Bancária (opcional)',
                                  prefixIcon: Icon(Icons.account_balance),
                                  border: OutlineInputBorder(),
                                ),
                                items: _contasBancarias.map((conta) {
                                  return DropdownMenuItem<int>(
                                    value: conta.id,
                                    child: Text(
                                      '${conta.banco ?? ''} ${conta.agencia ?? ''}/${conta.numero ?? ''}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(() => _contaBancariaId = v),
                              ),
                        const SizedBox(height: 12),

                        // Observação
                        TextFormField(
                          controller: _observacaoController,
                          decoration: const InputDecoration(
                            labelText: 'Observação (opcional)',
                            prefixIcon: Icon(Icons.notes),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 20),

                        // ── Selected Items ──
                        Container(
                          decoration: BoxDecoration(
                            color: GridColors.filterBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: GridColors.divider),
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Itens Selecionados',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: GridColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...List.generate(widget.selectedContas.length, (i) {
                                final conta = widget.selectedContas[i];
                                final valor = (conta['valor'] ?? 0).toDouble();
                                final descricao = conta['descricao'] ?? '';
                                final controllers = _itemControllers[i]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: GridColors.card,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: GridColors.borderSubtle),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                descricao,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: GridColors.secondarySoft,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'R\$ ${valor.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: GridColors.secondary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildSmallField(
                                                controllers['juros']!,
                                                'Juros',
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _buildSmallField(
                                                controllers['multa']!,
                                                'Multa',
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: _buildSmallField(
                                                controllers['desconto']!,
                                                'Desconto',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Actions ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text(GridTexts.cancel),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitBaixaLote,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Processando...'
                            : 'Confirmar Baixa (${widget.selectedIds.length})',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSmallField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildResultView() {
    final resp = _response!;
    final totalSucesso = resp.totalSucesso;
    final totalErros = resp.totalErros;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    resp.success ? Icons.check_circle : Icons.error_outline,
                    color: resp.success ? GridColors.success : GridColors.error,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    resp.success ? 'Baixa em Lote Concluída' : 'Baixa com Erros',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Divider(color: GridColors.divider),
              const SizedBox(height: 8),

              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: resp.success
                      ? GridColors.secondarySoft
                      : GridColors.errorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildResultStat('Total', resp.totalProcessados,
                        GridColors.textSecondary),
                    _buildResultStat('Sucesso', totalSucesso,
                        GridColors.success),
                    _buildResultStat(
                        'Erros', totalErros, GridColors.error),
                  ],
                ),
              ),

              if (resp.mensagemGeral != null) ...[
                const SizedBox(height: 12),
                Text(
                  resp.mensagemGeral!,
                  style: const TextStyle(fontSize: 13, color: GridColors.textMuted),
                ),
              ],
              const SizedBox(height: 12),

              // Per-item results
              if (resp.resultados.isNotEmpty) ...[
                const Text(
                  'Detalhes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: resp.resultados.length,
                    itemBuilder: (ctx, i) {
                      final r = resp.resultados[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          r.sucesso ? Icons.check_circle : Icons.cancel,
                          color: r.sucesso ? GridColors.success : GridColors.error,
                          size: 20,
                        ),
                        title: Text(
                          r.descricao ?? 'Conta #${r.contaId}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          r.mensagem ?? (r.sucesso ? 'Baixada com sucesso' : 'Erro'),
                          style: TextStyle(
                            fontSize: 11,
                            color: r.sucesso
                                ? GridColors.success
                                : GridColors.error,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, resp.success),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: resp.success
                          ? GridColors.secondary
                          : GridColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(resp.success ? 'Concluir' : 'Fechar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: GridColors.textMuted),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataBaixa,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _dataBaixa) {
      setState(() => _dataBaixa = picked);
    }
  }

  Future<void> _submitBaixaLote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final itens = <BaixaLoteItem>[];
      for (int i = 0; i < widget.selectedIds.length; i++) {
        final controllers = _itemControllers[i]!;
        final juros = double.tryParse(controllers['juros']!.text) ?? 0;
        final multa = double.tryParse(controllers['multa']!.text) ?? 0;
        final desconto = double.tryParse(controllers['desconto']!.text) ?? 0;

        itens.add(BaixaLoteItem(
          contaId: widget.selectedIds[i],
          valorJuros: juros > 0 ? juros : null,
          valorMulta: multa > 0 ? multa : null,
          valorDesconto: desconto > 0 ? desconto : null,
        ));
      }

      final request = BaixaLoteRequest(
        dataBaixa: _dataBaixa,
        formaPagamentoId: _formaPagamentoId,
        contaBancariaId: _contaBancariaId,
        observacao: _observacaoController.text,
        itens: itens,
      );

      final service = BaixaLoteService();
      final BaixaLoteResponse response;

      if (widget.isPagar) {
        response = await service.baixaLotePagar(widget.selectedIds, request);
      } else {
        response = await service.baixaLoteReceber(widget.selectedIds, request);
      }

      if (mounted) {
        setState(() {
          _response = response;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _response = BaixaLoteResponse(
            success: false,
            totalProcessados: 0,
            totalSucesso: 0,
            totalErros: 0,
            resultados: [],
            mensagemGeral: 'Erro inesperado: $e',
          );
          _isSubmitting = false;
        });
      }
    }
  }
}

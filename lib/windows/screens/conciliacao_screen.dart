import 'package:flutter/material.dart';

import '../../../services/conta_bancaria_caller.dart';
import '../../../services/conciliacao_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class ConciliacaoScreen extends StatefulWidget {
  const ConciliacaoScreen({super.key});

  @override
  State<ConciliacaoScreen> createState() => _ConciliacaoScreenState();
}

class _ConciliacaoScreenState extends State<ConciliacaoScreen> {
  final ContaBancariaCaller _contaCaller = ContaBancariaCaller();

  List<Map<String, dynamic>> _contas = [];
  Map<String, dynamic>? _contaSelecionada;
  List<dynamic> _pendentes = [];
  List<dynamic> _conciliacoes = [];
  bool _loadingPendentes = false;
  bool _loadingConciliacoes = false;
  bool _autoConciliando = false;

  String? _filtroDataInicio;
  String? _filtroDataFim;

  @override
  void initState() {
    super.initState();
    _carregarContas();
  }

  Future<void> _carregarContas() async {
    final contas = await _contaCaller.fetchContas(context);
    if (!mounted) return;
    setState(() => _contas = contas.map((c) => c.toJson()).toList());
  }

  Future<void> _carregarPendentes() async {
    if (_contaSelecionada == null) return;
    setState(() => _loadingPendentes = true);
    final data =
        await ConciliacaoCaller.listarPendentes(_contaSelecionada!['id'] as int);
    if (!mounted) return;
    setState(() {
      _pendentes = data;
      _loadingPendentes = false;
    });
  }

  Future<void> _carregarConciliacoes() async {
    setState(() => _loadingConciliacoes = true);
    final data = await ConciliacaoCaller.listarConciliacoes(
      contaBancariaId: _contaSelecionada?['id'] as int?,
      dataInicio: _filtroDataInicio,
      dataFim: _filtroDataFim,
    );
    if (!mounted) return;
    setState(() {
      _conciliacoes = data;
      _loadingConciliacoes = false;
    });
  }

  Future<void> _autoConciliar() async {
    if (_contaSelecionada == null) return;
    setState(() => _autoConciliando = true);
    final result = await ConciliacaoCaller.autoConciliar(
        _contaSelecionada!['id'] as int);
    if (!mounted) return;
    setState(() => _autoConciliando = false);
    _snack(
        result['success'] ? GridTexts.autoReconcileSuccess : result['message'],
        error: !result['success']);
    if (result['success']) _carregarPendentes();
  }

  Future<void> _desfazerConciliacao(int id) async {
    final ok = await ConciliacaoCaller.desfazerConciliacao(id);
    if (!mounted) return;
    if (ok) {
      _snack(GridTexts.reconciliationUndone);
      _carregarConciliacoes();
    } else {
      _snack(GridTexts.undoError, error: true);
    }
  }

  void _abrirDialogConciliar(Map<String, dynamic> transacao) async {
    final lancamentos = await ConciliacaoCaller.listarLancamentos(null);
    if (!mounted) return;

    final sugestoes = await ConciliacaoCaller.sugerir(
        _contaSelecionada!['id'] as int);
    if (!mounted) return;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => _ConciliarDialog(
        transacao: transacao,
        lancamentos: lancamentos,
        sugestoes: sugestoes,
        onConfirmar: (lancamentoId, lancamentoTipo, observacao) async {
          Navigator.pop(ctx);
          final result = await ConciliacaoCaller.conciliar(
            transacaoId: transacao['id'] as int,
            lancamentoId: lancamentoId,
            lancamentoTipo: lancamentoTipo,
            observacao: observacao,
          );
          if (!mounted) return;
          _snack(
              result['success'] ? GridTexts.reconciliationDone : result['message'],
              error: !result['success']);
          if (result['success']) _carregarPendentes();
        },
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: error ? GridColors.error : GridColors.success,
      content: Text(msg),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: GridColors.pageBackground,
        appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
          title: const Text('Conciliação Bancária'),
          elevation: 0,
          bottom: const TabBar(
            labelColor: GridColors.textPrimary,
            unselectedLabelColor: GridColors.textPrimaryMuted,
            indicatorColor: GridColors.textPrimary,
            tabs: [
              Tab(text: 'Pendentes + Sugestões'),
              Tab(text: 'Conciliações Realizadas'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPendentesTab(),
            _buildRealizadasTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildContaDropdown() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: DropdownButtonFormField<Map<String, dynamic>>(
        value: _contaSelecionada,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Conta Bancária',
          border: OutlineInputBorder(),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          fillColor: GridColors.textPrimary,
          filled: true,
        ),
        items: _contas.map((c) {
          final label =
              '${c['banco'] ?? ''} - ${c['numero'] ?? ''}${c['agencia'] != null ? ' (' + c['agencia'].toString() + ')' : ''}';
          return DropdownMenuItem(
            value: c,
            child: Text(label, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (v) {
          setState(() => _contaSelecionada = v);
          if (v != null) {
            _carregarPendentes();
            _carregarConciliacoes();
          }
        },
      ),
    );
  }

  Widget _buildPendentesTab() {
    return Column(
      children: [
        _buildContaDropdown(),
        if (_contaSelecionada != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _autoConciliando ? null : _autoConciliar,
                  icon: _autoConciliando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: GridColors.textPrimary),
                        )
                      : const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(_autoConciliando
                      ? GridTexts.autoReconciling
                      : GridTexts.autoReconcile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.secondary,
                    foregroundColor: GridColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _loadingPendentes ? null : _carregarPendentes,
                  icon: _loadingPendentes
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: GridColors.textPrimary),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text(GridTexts.refresh),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.info,
                    foregroundColor: GridColors.textPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
        Expanded(
          child: _pendentes.isEmpty && !_loadingPendentes
              ? const Center(
                  child: Text(GridTexts.noPendingTransaction,
                      style: TextStyle(color: Colors.grey, fontSize: 14)))
              : _buildPendentesTable(),
        ),
      ],
    );
  }

  Widget _buildPendentesTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor:
              WidgetStateProperty.all(GridColors.secondaryLight),
          headingTextStyle: const TextStyle(
              color: GridColors.textPrimary, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Descrição')),
            DataColumn(label: Text('Valor'), numeric: true),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _pendentes.map((item) {
            final t = item is Map<String, dynamic>
                ? item
                : <String, dynamic>{};
            return DataRow(cells: [
              DataCell(Text(_fmtData(t['data']?.toString() ?? ''))),
              DataCell(SizedBox(
                  width: 200,
                  child: Text(t['descricao']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(Text(_fmtValor((t['valor'] ?? 0).toDouble()))),
              DataCell(Text(t['tipo']?.toString() ?? '')),
              DataCell(
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirDialogConciliar(t),
                    icon: const Icon(Icons.check_circle, size: 14),
                    label: const Text(GridTexts.reconcile, style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.success,
                      foregroundColor: GridColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRealizadasTab() {
    return Column(
      children: [
        _buildContaDropdown(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 160,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Data Início',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    fillColor: GridColors.textPrimary,
                    filled: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    _filtroDataInicio = v;
                    _carregarConciliacoes();
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 160,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Data Fim',
                    hintText: 'YYYY-MM-DD',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    fillColor: GridColors.textPrimary,
                    filled: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  onChanged: (v) {
                    _filtroDataFim = v;
                    _carregarConciliacoes();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadingConciliacoes ? null : _carregarConciliacoes,
                icon: _loadingConciliacoes
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: GridColors.textPrimary),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text(GridTexts.refresh),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.info,
                  foregroundColor: GridColors.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _conciliacoes.isEmpty && !_loadingConciliacoes
              ? const Center(
                  child: Text(GridTexts.noReconciliationFound,
                      style: TextStyle(color: Colors.grey, fontSize: 14)))
              : _buildRealizadasTable(),
        ),
      ],
    );
  }

  Widget _buildRealizadasTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor:
              WidgetStateProperty.all(GridColors.secondaryLight),
          headingTextStyle: const TextStyle(
              color: GridColors.textPrimary, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text('Data')),
            DataColumn(label: Text('Transação')),
            DataColumn(label: Text('Lançamento')),
            DataColumn(label: Text('Tipo')),
            DataColumn(label: Text('Valor')),
            DataColumn(label: Text('Ações')),
          ],
          rows: _conciliacoes.map((item) {
            final c = item is Map<String, dynamic>
                ? item
                : <String, dynamic>{};
            return DataRow(cells: [
              DataCell(Text(_fmtData(c['dataConciliacao']?.toString() ?? ''))),
              DataCell(SizedBox(
                  width: 150,
                  child: Text(c['transacaoDescricao']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(SizedBox(
                  width: 150,
                  child: Text(c['lancamentoDescricao']?.toString() ?? '',
                      overflow: TextOverflow.ellipsis))),
              DataCell(Text(c['tipoConciliacao']?.toString() ?? '')),
              DataCell(Text(_fmtValor((c['valor'] ?? 0).toDouble()))),
              DataCell(
                SizedBox(
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmarDesfazer(c['id'] as int),
                    icon: const Icon(Icons.undo, size: 14),
                    label: const Text(GridTexts.undo,
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GridColors.warning,
                      foregroundColor: GridColors.textPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _confirmarDesfazer(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desfazer Conciliação'),
        content: const Text('Tem certeza que deseja desfazer esta conciliação?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text(GridTexts.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(GridTexts.confirm)),
        ],
      ),
    );
    if (confirm == true) _desfazerConciliacao(id);
  }

  String _fmtData(String d) {
    if (d.length >= 10) return d.substring(0, 10);
    return d;
  }

  String _fmtValor(double v) {
    return 'R\$${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}

class _ConciliarDialog extends StatefulWidget {
  final Map<String, dynamic> transacao;
  final List<dynamic> lancamentos;
  final List<dynamic> sugestoes;
  final Future<void> Function(
      int lancamentoId, String lancamentoTipo, String observacao) onConfirmar;

  const _ConciliarDialog({
    required this.transacao,
    required this.lancamentos,
    required this.sugestoes,
    required this.onConfirmar,
  });

  @override
  State<_ConciliarDialog> createState() => _ConciliarDialogState();
}

class _ConciliarDialogState extends State<_ConciliarDialog> {
  Map<String, dynamic>? _lancamentoSelecionado;
  final _obsController = TextEditingController();
  bool _confirmando = false;

  List<Map<String, dynamic>> get _lancamentosList =>
      widget.lancamentos.map((e) => Map<String, dynamic>.from(e)).toList();

  List<Map<String, dynamic>> get _sugestoesList =>
      widget.sugestoes.map((e) => Map<String, dynamic>.from(e)).toList();

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transacao = widget.transacao;
    final valorTransacao = (transacao['valor'] ?? 0).toDouble();

    return AlertDialog(
      title: const Text('Conciliar Transação'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GridColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transação: ${transacao['descricao'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                        'Valor: R\$${valorTransacao.toStringAsFixed(2).replaceAll('.', ',')}'),
                    Text('Data: ${transacao['data']?.toString() ?? ''}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_sugestoesList.isNotEmpty) ...[
                const Text('Sugestões Automáticas:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: GridColors.secondary)),
                const SizedBox(height: 8),
                ..._sugestoesList.map((s) {
                  final score = (s['score'] ?? 0).toDouble();
                  final cor = score >= 0.8
                      ? GridColors.suggestionHigh
                      : score >= 0.5
                          ? GridColors.suggestionMedium
                          : GridColors.textPrimary;
                  return Card(
                    color: cor,
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(s['descricao']?.toString() ?? ''),
                      subtitle: Text(
                          'Valor: R\$${((s['valor'] ?? 0).toDouble()).toStringAsFixed(2)} - Score: ${(score * 100).toStringAsFixed(0)}%'),
                      trailing: TextButton(
                        onPressed: () {
                          final lancId = s['lancamentoId'] ?? s['id'];
                          if (lancId != null) {
                            final found = _lancamentosList.firstWhere(
                                (l) => l['id'] == lancId,
                                orElse: () => <String, dynamic>{});
                            if (found.isNotEmpty) {
                              setState(() => _lancamentoSelecionado = found);
                            }
                          }
                        },
                        child: const Text('Selecionar'),
                      ),
                    ),
                  );
                }),
                const Divider(),
              ],
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: _lancamentoSelecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Lançamento Financeiro',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _lancamentosList.map((l) {
                  final label =
                      '${l['descricao'] ?? ''} - R\$${((l['valor'] ?? 0).toDouble()).toStringAsFixed(2)}';
                  return DropdownMenuItem(
                    value: l,
                    child: Text(label, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (v) =>
                    setState(() => _lancamentoSelecionado = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _obsController,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(GridTexts.cancel),
        ),
        ElevatedButton.icon(
          onPressed: (_lancamentoSelecionado == null || _confirmando)
              ? null
              : _confirmar,
          icon: _confirmando
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: GridColors.textPrimary),
                )
              : const Icon(Icons.check_circle, size: 18),
          label: Text(_confirmando ? GridTexts.confirming : GridTexts.confirm),
          style: ElevatedButton.styleFrom(
            backgroundColor: GridColors.success,
            foregroundColor: GridColors.textPrimary,
            disabledBackgroundColor: GridColors.disabledBackground,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmar() async {
    if (_lancamentoSelecionado == null) return;
    setState(() => _confirmando = true);
    await widget.onConfirmar(
      _lancamentoSelecionado!['id'] as int,
      _lancamentoSelecionado!['tipo']?.toString() ?? 'PAGAR',
      _obsController.text,
    );
  }
}

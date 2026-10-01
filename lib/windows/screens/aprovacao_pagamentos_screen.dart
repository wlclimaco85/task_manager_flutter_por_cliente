import 'package:flutter/material.dart';
import '../../services/aprovacao_pagamento_caller.dart';
import '../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';
import '../../utils/utils.dart';

class WebAprovacaoPagamentosScreen extends StatefulWidget {
  const WebAprovacaoPagamentosScreen({super.key});

  @override
  State<WebAprovacaoPagamentosScreen> createState() =>
      _WebAprovacaoPagamentosScreenState();
}

class _WebAprovacaoPagamentosScreenState
    extends State<WebAprovacaoPagamentosScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _contaPagarIdCtrl = TextEditingController();

  List<Map<String, dynamic>> _fila = [];
  List<Map<String, dynamic>> _historico = [];
  bool _loadingFila = false;
  bool _loadingHistorico = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _carregarFila();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _contaPagarIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarFila() async {
    setState(() => _loadingFila = true);
    try {
      final empresaId = pegarEmpresaLogada() ?? 0;
      final res = await AprovacaoPagamentoCaller.fila(empresaId: empresaId);
      if (res.isSuccess && res.body != null) {
        _fila = _extrairLista(res.body!);
      } else {
        _fila = [];
      }
    } catch (_) {
      _fila = [];
    }
    if (mounted) setState(() => _loadingFila = false);
  }

  Future<void> _carregarHistorico() async {
    setState(() => _loadingHistorico = true);
    try {
      final id = int.tryParse(_contaPagarIdCtrl.text);
      if (id != null) {
        final res = await AprovacaoPagamentoCaller.historico(contaPagarId: id);
        if (res.isSuccess && res.body != null) {
          _historico = _extrairLista(res.body!);
        } else {
          _historico = [];
        }
      } else {
        _historico = [];
      }
    } catch (_) {
      _historico = [];
    }
    if (mounted) setState(() => _loadingHistorico = false);
  }

  List<Map<String, dynamic>> _extrairLista(Map<String, dynamic> body) {
    final d = body['data'];
    if (d is List) {
      return d.map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (d is Map) {
      final inner = d['dados'] ?? d['content'];
      if (inner is List) {
        return inner.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    return [];
  }

  Future<void> _aprovar(dynamic id) async {
    final justificativaCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GridTexts.approvePayment),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Deseja aprovar este pagamento?'),
              const SizedBox(height: 12),
              TextField(
                controller: justificativaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Justificativa (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style:
                ElevatedButton.styleFrom(backgroundColor: GridColors.success),
            child: const Text(GridTexts.approve),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await AprovacaoPagamentoCaller.aprovar(
      aprovacaoId: id,
      justificativa: justificativaCtrl.text.isEmpty
          ? 'Aprovado'
          : justificativaCtrl.text,
    );
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GridTexts.paymentApprovalDone(true)),
          backgroundColor: GridColors.success,
        ),
      );
      _carregarFila();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${res.statusCode}'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  Future<void> _reprovar(dynamic id) async {
    final justificativaCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GridTexts.rejectPayment),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Informe a justificativa da reprovação:'),
              const SizedBox(height: 12),
              TextField(
                controller: justificativaCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: GridTexts.justificationRequired,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (justificativaCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(GridTexts.justificationRequired),
                    backgroundColor: GridColors.error,
                  ),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: GridColors.error),
            child: const Text(GridTexts.reject),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final res = await AprovacaoPagamentoCaller.reprovar(
      aprovacaoId: id,
      justificativa: justificativaCtrl.text,
    );
    if (!mounted) return;
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(GridTexts.paymentApprovalDone(false)),
          backgroundColor: GridColors.success,
        ),
      );
      _carregarFila();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${res.statusCode}'),
          backgroundColor: GridColors.error,
        ),
      );
    }
  }

  void _solicitarAprovacao() {
    final id = int.tryParse(_contaPagarIdCtrl.text);
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um ID de conta a pagar válido'),
          backgroundColor: GridColors.error,
        ),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GridTexts.requestApproval),
        content: Text('Solicitar aprovação para a conta #$id?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await AprovacaoPagamentoCaller.solicitar(id);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(res.isSuccess
                    ? GridTexts.purchaseApprovalRequested
                    : 'Erro: ${res.statusCode}'),
                backgroundColor:
                    res.isSuccess ? GridColors.success : GridColors.error,
              ));
              _carregarFila();
            },
            child: const Text(GridTexts.confirm),
          ),
        ],
      ),
    );
  }

  String _fmtValor(dynamic v) {
    final valor = (v is num) ? v.toDouble() : 0.0;
    return 'R\$${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 56,
          color: GridColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.checklist, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(GridTexts.paymentApprovalTitle,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 36,
                      child: TextField(
                        controller: _contaPagarIdCtrl,
                        decoration: InputDecoration(
                          hintText: GridTexts.accountPayableId,
                          hintStyle: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide:
                                const BorderSide(color: Colors.white38),
                          ),
                          fillColor: Colors.white12,
                          filled: true,
                        ),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: _solicitarAprovacao,
                      icon: const Icon(Icons.send, size: 14),
                      label: const Text(GridTexts.requestApproval,
                          style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GridColors.secondary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  if (_tabCtrl.index == 0) {
                    _carregarFila();
                  } else {
                    _carregarHistorico();
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: GridTexts.refresh,
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 280,
                child: TabBar(
                  controller: _tabCtrl,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: GridTexts.approvalQueueTab),
                    Tab(text: GridTexts.history),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _buildFilaTab(),
              _buildHistoricoTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilaTab() {
    if (_loadingFila) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fila.isEmpty) {
      return const Center(
        child: Text(GridTexts.noPendingApproval,
            style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor:
              WidgetStateProperty.all(GridColors.primary),
          headingTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text(GridTexts.accountPayableId)),
            DataColumn(label: Text(GridTexts.supplier)),
            DataColumn(label: Text(GridTexts.value)),
            DataColumn(label: Text(GridTexts.dueDate)),
            DataColumn(label: Text(GridTexts.requester)),
            DataColumn(label: Text(GridTexts.actions)),
          ],
          rows: _fila.map((item) {
            return DataRow(cells: [
              DataCell(Text('#${item['contaPagarId'] ?? item['id'] ?? '-'}')),
              DataCell(Text(item['fornecedorNome']?.toString() ??
                  item['parceiroNome']?.toString() ??
                  '-')),
              DataCell(Text(_fmtValor(item['valor'] ?? item['valorTotal']),
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Text(
                  item['dataVencimento']?.toString().substring(0, 10) ??
                      '-')),
              DataCell(Text(item['solicitanteNome']?.toString() ?? '-')),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: GridTexts.approvePayment,
                    child: IconButton(
                      icon: const Icon(Icons.check_circle,
                          color: GridColors.success, size: 22),
                      onPressed: () =>
                          _aprovar(item['id'] ?? item['contaPagarId']),
                    ),
                  ),
                  Tooltip(
                    message: GridTexts.rejectPayment,
                    child: IconButton(
                      icon: const Icon(Icons.cancel,
                          color: GridColors.error, size: 22),
                      onPressed: () =>
                          _reprovar(item['id'] ?? item['contaPagarId']),
                    ),
                  ),
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_loadingHistorico) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historico.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(GridTexts.noHistoryFoundShort,
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _carregarHistorico,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text(GridTexts.loadHistory),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor:
              WidgetStateProperty.all(GridColors.primary),
          headingTextStyle: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
          columns: const [
            DataColumn(label: Text(GridTexts.accountPayableId)),
            DataColumn(label: Text(GridTexts.supplier)),
            DataColumn(label: Text(GridTexts.value)),
            DataColumn(label: Text(GridTexts.status)),
            DataColumn(label: Text(GridTexts.justification)),
            DataColumn(label: Text(GridTexts.date)),
          ],
          rows: _historico.map((item) {
            final aprovado = item['aprovado'] == true ||
                item['status']?.toString() == 'APROVADO';
            return DataRow(cells: [
              DataCell(Text('#${item['contaPagarId'] ?? item['id'] ?? '-'}')),
              DataCell(Text(item['fornecedorNome']?.toString() ??
                  item['parceiroNome']?.toString() ??
                  '-')),
              DataCell(Text(_fmtValor(item['valor']),
                  style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: (aprovado ? GridColors.success : GridColors.error)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    aprovado ? 'APROVADO' : 'REPROVADO',
                    style: TextStyle(
                      color:
                          aprovado ? GridColors.successDark : GridColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              DataCell(Text(item['justificativa']?.toString() ?? '-')),
              DataCell(Text(
                  item['dataAprovacao']?.toString().substring(0, 10) ??
                      item['data']?.toString().substring(0, 10) ??
                      '-')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

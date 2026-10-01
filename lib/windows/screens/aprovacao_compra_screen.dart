import 'package:flutter/material.dart';
import '../../constants/custom_colors.dart';
import '../../services/aprovacao_compra_caller.dart';
import '../../utils/grid_texts.dart';

class AprovacaoCompraScreen extends StatefulWidget {
  const AprovacaoCompraScreen({super.key});

  @override
  State<AprovacaoCompraScreen> createState() => _AprovacaoCompraScreenState();
}

class _AprovacaoCompraScreenState extends State<AprovacaoCompraScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _pedidoIdCtrl = TextEditingController();

  List<Map<String, dynamic>> _fila = [];
  Map<String, dynamic>? _pedidoDetalhe;
  bool _loadingFila = false;
  bool _loadingPedido = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _carregarFila();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _pedidoIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarFila() async {
    setState(() => _loadingFila = true);
    try {
      final res = await AprovacaoCompraCaller.fila();
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

  Future<void> _carregarPedido() async {
    final id = _pedidoIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => _loadingPedido = true);
    try {
      final res = await AprovacaoCompraCaller.pedido(id);
      if (res.isSuccess && res.body != null) {
        _pedidoDetalhe = res.body;
      } else {
        _pedidoDetalhe = null;
      }
    } catch (_) {
      _pedidoDetalhe = null;
    }
    if (mounted) setState(() => _loadingPedido = false);
  }

  List<Map<String, dynamic>> _extrairLista(Map<String, dynamic> body) {
    if (body.containsKey('data') && body['data'] is List) {
      return List<Map<String, dynamic>>.from(body['data']);
    }
    if (body.containsKey('content') && body['content'] is List) {
      return List<Map<String, dynamic>>.from(body['content']);
    }
    final values = body.values.whereType<List>();
    if (values.isNotEmpty) {
      return List<Map<String, dynamic>>.from(values.first);
    }
    return [];
  }

  Future<void> _confirmarAcao(
      Map<String, dynamic> item, bool isAprovar) async {
    final justifCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAprovar ? GridTexts.approvePurchase : GridTexts.rejectPurchase),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(GridTexts.purchaseOrderLabel(
                '${item['pedido'] ?? item['numero'] ?? ''}')),
            const SizedBox(height: 12),
            TextField(
              controller: justifCtrl,
              decoration: const InputDecoration(
                labelText: GridTexts.justificationRequired,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (justifCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx, justifCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isAprovar ? GridColors.success : GridColors.error,
              foregroundColor: GridColors.buttonText,
            ),
            child: Text(isAprovar ? GridTexts.approve : GridTexts.reject),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    final id = item['id'];
    setState(() => _loadingFila = true);
    try {
      final res = isAprovar
          ? await AprovacaoCompraCaller.aprovar(
              aprovacaoId: id, justificativa: result)
          : await AprovacaoCompraCaller.reprovar(
              aprovacaoId: id, justificativa: result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: res.isSuccess ? GridColors.success : GridColors.error,
          content: Text(res.isSuccess
              ? GridTexts.purchaseApprovalDone(isAprovar)
              : GridTexts.errorWithStatus(res.statusCode)),
        ));
        if (res.isSuccess) await _carregarFila();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: GridColors.error,
          content: Text(GridTexts.genericError(e.toString())),

        ));
      }
    }
    if (mounted) setState(() => _loadingFila = false);
  }

  Future<void> _solicitarAprovacao() async {
    final pedidoIdCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(GridTexts.requestApproval),
        content: TextField(
          controller: pedidoIdCtrl,
          decoration: const InputDecoration(
            labelText: GridTexts.purchaseOrderRequestId,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, pedidoIdCtrl.text.trim()),
            child: const Text(GridTexts.requestApproval),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;
    setState(() => _loadingFila = true);
    try {
      final res = await AprovacaoCompraCaller.solicitar(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: res.isSuccess ? GridColors.success : GridColors.error,
          content: Text(res.isSuccess
              ? GridTexts.purchaseApprovalRequested
              : GridTexts.errorWithStatus(res.statusCode)),
        ));
        if (res.isSuccess) await _carregarFila();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: GridColors.error,
          content: Text(GridTexts.genericError(e.toString())),

        ));
      }
    }
    if (mounted) setState(() => _loadingFila = false);
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
              const Icon(Icons.verified_user, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
                GridTexts.purchaseApprovalTitle,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 280,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: GridTexts.approvalQueueTab),
                    Tab(text: GridTexts.orderDetailsTab),
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
              _buildDetalheTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: _solicitarAprovacao,
                icon: const Icon(Icons.send, size: 18),
                label: const Text(GridTexts.requestApproval),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.buttonBackground,
                  foregroundColor: GridColors.buttonText,
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loadingFila ? null : _carregarFila,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(GridTexts.refresh),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildFilaGrid()),
      ],
    );
  }

  Widget _buildFilaGrid() {
    if (_loadingFila) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_fila.isEmpty) {
      return const Center(child: Text(GridTexts.noPendingApproval));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text(GridTexts.order)),
          DataColumn(label: Text(GridTexts.supplier)),
          DataColumn(label: Text(GridTexts.value)),
          DataColumn(label: Text(GridTexts.requester)),
          DataColumn(label: Text(GridTexts.date)),
          DataColumn(label: Text(GridTexts.actions)),
        ],
        rows: _fila.map((item) {
          return DataRow(cells: [
            DataCell(Text(item['pedido']?.toString() ??
                item['numero']?.toString() ??
                '')),
            DataCell(Text(item['fornecedor']?.toString() ?? '-')),
            DataCell(Text(_formatValor(item['valor']))),
            DataCell(Text(item['solicitante']?.toString() ?? '')),
            DataCell(Text(_formatData(item['data'] ?? item['createdAt']))),
            DataCell(Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check_circle,
                      color: GridColors.success, size: 20),
                  tooltip: GridTexts.approve,
                  onPressed: () => _confirmarAcao(item, true),
                ),
                IconButton(
                  icon: const Icon(Icons.cancel,
                      color: GridColors.error, size: 20),
                  tooltip: GridTexts.reject,
                  onPressed: () => _confirmarAcao(item, false),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildDetalheTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _pedidoIdCtrl,
                  decoration: const InputDecoration(
                    labelText: GridTexts.purchaseOrderId,
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadingPedido ? null : _carregarPedido,
                icon: const Icon(Icons.search, size: 18),
                label: const Text(GridTexts.search),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(child: _buildPedidoDetalhe()),
      ],
    );
  }

  Widget _buildPedidoDetalhe() {
    if (_loadingPedido) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_pedidoDetalhe == null) {
      return const Center(child: Text(GridTexts.noOrderIdProvided));
    }
    final p = _pedidoDetalhe!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(GridTexts.purchaseOrderTitle('${p['id'] ?? p['numero'] ?? ''}'),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _infoRow(GridTexts.supplier, p['fornecedor']?.toString() ?? '-'),
                  _infoRow(GridTexts.totalValue,
                      _formatValor(p['valor'] ?? p['totalGeral'])),
                  _infoRow(GridTexts.status, p['status']?.toString() ?? '-'),
                  _infoRow(GridTexts.date, _formatData(p['data'] ?? p['dataEmissao'])),
                  _infoRow(GridTexts.notes, p['observacao']?.toString() ?? '-'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (p['itens'] is List && (p['itens'] as List).isNotEmpty) ...[
            const Text(GridTexts.orderItems,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DataTable(
              columns: const [
                DataColumn(label: Text(GridTexts.product)),
                DataColumn(label: Text(GridTexts.quantityShort)),
                DataColumn(label: Text(GridTexts.unitValue)),
                DataColumn(label: Text(GridTexts.totalLabel)),
              ],
              rows: (p['itens'] as List).map((i) {
                final item = Map<String, dynamic>.from(i);
                return DataRow(cells: [
                  DataCell(Text(item['produtoNome']?.toString() ?? '-')),
                  DataCell(Text(item['quantidade']?.toString() ?? '')),
                  DataCell(Text(_formatValor(item['valorUnitario']))),
                  DataCell(Text(_formatValor(item['total']))),
                ]);
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatValor(dynamic val) {
    if (val == null) return '';
    final num v = (val is num) ? val : double.tryParse(val.toString()) ?? 0;
    return '${GridTexts.currencySymbol} ${v.toStringAsFixed(2)}';
  }

  String _formatData(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.parse(val.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return val.toString();
    }
  }
}

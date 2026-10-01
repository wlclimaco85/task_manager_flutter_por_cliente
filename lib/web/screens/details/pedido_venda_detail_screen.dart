import 'package:flutter/material.dart';
import '../../../models/pedido_venda_model.dart';
import '../../../services/pedido_venda_service.dart';
import '../../../utils/grid_colors.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

class PedidoVendaDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const PedidoVendaDetailScreen({super.key, required this.item});

  @override
  State<PedidoVendaDetailScreen> createState() => _State();
}

class _State extends State<PedidoVendaDetailScreen> {
  int _tab = 0;
  bool _isLoading = false;
  List<PedidoVendaItem> _itens = [];
  List<PedidoVendaHistorico> _historico = [];

  // Cabeçalho
  late TextEditingController _numeroCtrl;
  late TextEditingController _clienteCtrl;
  late TextEditingController _dataEmissaoCtrl;
  late TextEditingController _dataEntregaCtrl;
  late TextEditingController _statusCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _observacaoCtrl;

  bool get _isNovo => widget.item['id'] == null;
  int get _pedidoId => widget.item['id'] as int? ?? 0;

  @override
  void initState() {
    super.initState();
    _numeroCtrl = TextEditingController(text: widget.item['numero']?.toString() ?? '');
    _clienteCtrl = TextEditingController(text: widget.item['clienteNome']?.toString() ?? '');
    _dataEmissaoCtrl = TextEditingController(text: widget.item['dataEmissao']?.toString() ?? '');
    _dataEntregaCtrl = TextEditingController(text: widget.item['dataEntrega']?.toString() ?? '');
    _statusCtrl = TextEditingController(text: widget.item['status']?.toString() ?? 'RASCUNHO');
    _totalCtrl = TextEditingController(text: (widget.item['totalGeral'] ?? 0.0).toString());
    _observacaoCtrl = TextEditingController(text: widget.item['observacao']?.toString() ?? '');

    if (!_isNovo) {
      _loadItens();
      _loadHistorico();
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _clienteCtrl.dispose();
    _dataEmissaoCtrl.dispose();
    _dataEntregaCtrl.dispose();
    _statusCtrl.dispose();
    _totalCtrl.dispose();
    _observacaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadItens() async {
    setState(() => _isLoading = true);
    try {
      final itens = await PedidoVendaService.fetchItens(_pedidoId);
      setState(() => _itens = itens);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _loadHistorico() async {
    setState(() => _isLoading = true);
    try {
      final historico = await PedidoVendaService.fetchHistorico(_pedidoId);
      setState(() => _historico = historico);
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _red,
        foregroundColor: Colors.white,
        title: Text(_isNovo ? 'Novo Pedido de Venda' : 'Pedido #${_numeroCtrl.text}'),
        actions: [
          if (!_isNovo)
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(child: const Text('Editar'), onTap: () {}),
                PopupMenuItem(child: const Text('Aprovar'), onTap: () {}),
                PopupMenuItem(child: const Text('Cancelar'), onTap: () {}),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Cabeçalho (informações principais) ─────────────────────────────
          Container(
            color: _bg,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha 1: Número, Cliente, Data Emissão, Status
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: _buildField('Número', _numeroCtrl, enabled: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildField('Cliente', _clienteCtrl, enabled: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField('Data Emissão', _dataEmissaoCtrl, enabled: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField('Status', _statusCtrl, enabled: false),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildField('Número', _numeroCtrl, enabled: false),
                      const SizedBox(height: 8),
                      _buildField('Cliente', _clienteCtrl, enabled: false),
                      const SizedBox(height: 8),
                      _buildField('Data Emissão', _dataEmissaoCtrl, enabled: false),
                      const SizedBox(height: 8),
                      _buildField('Status', _statusCtrl, enabled: false),
                    ],
                  ),
                const SizedBox(height: 12),
                // Linha 2: Data Entrega, Total, Desconto
                if (!isMobile)
                  Row(
                    children: [
                      Expanded(
                        child: _buildField('Data Entrega', _dataEntregaCtrl, enabled: false),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildField('Total', _totalCtrl, enabled: false),
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _buildField('Data Entrega', _dataEntregaCtrl, enabled: false),
                      const SizedBox(height: 8),
                      _buildField('Total', _totalCtrl, enabled: false),
                    ],
                  ),
                if (_observacaoCtrl.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildField('Observação', _observacaoCtrl, enabled: false, maxLines: 2),
                ],
              ],
            ),
          ),
          // ── Abas (Itens / Histórico) ──────────────────────────────────────
          Container(
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tab == 0 ? _red : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Itens (${_itens.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _tab == 0 ? _red : _grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _tab == 1 ? _red : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Histórico (${_historico.length})',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _tab == 1 ? _red : _grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Conteúdo das abas ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tab == 0
                    ? _buildItensTab()
                    : _buildHistoricoTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {bool enabled = true, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _grey, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderSide: const BorderSide(color: _bord)),
            disabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: _bord)),
            enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: _bord)),
            focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: _red, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildItensTab() {
    if (_itens.isEmpty) {
      return Center(
        child: Text(
          'Nenhum item adicionado',
          style: TextStyle(fontSize: 14, color: _grey),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: DataTable(
        columns: [
          DataColumn(label: Text('Produto', style: TextStyle(color: _dark, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Qtd', style: TextStyle(color: _dark, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('V.Unit', style: TextStyle(color: _dark, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Desconto', style: TextStyle(color: _dark, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('Total', style: TextStyle(color: _dark, fontWeight: FontWeight.bold))),
        ],
        rows: _itens
            .map(
              (item) => DataRow(cells: [
                DataCell(Text(item.produtoNome ?? item.descricao ?? '', style: const TextStyle(fontSize: 12))),
                DataCell(Text((item.quantidade ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                DataCell(Text((item.valorUnitario ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                DataCell(Text((item.desconto ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 12))),
                DataCell(Text((item.total ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
              ]),
            )
            .toList(),
      ),
    );
  }

  Widget _buildHistoricoTab() {
    if (_historico.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma alteração registrada',
          style: TextStyle(fontSize: 14, color: _grey),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: _historico
            .map(
              (h) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${h.statusAnterior} → ${h.statusNovo}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: _dark, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            h.data ?? '',
                            style: const TextStyle(fontSize: 11, color: _grey),
                          ),
                        ],
                      ),
                      if (h.observacao?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          h.observacao ?? '',
                          style: const TextStyle(fontSize: 12, color: _dark),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

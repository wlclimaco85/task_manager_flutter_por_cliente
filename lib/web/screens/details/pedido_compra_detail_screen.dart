import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../utils/grid_colors.dart';
import '../../../models/auth_utility.dart';
import '../../../models/pedido_compra_model.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

const _red = GridColors.primary;
const _green = GridColors.secondary;
const _bord = Color(0xFFDDDDDD);
const _grey = Color(0xFF757575);
const _dark = Color(0xFF212121);
const _bg = Color(0xFFF5F5F5);

class PedidoCompraDetailScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  const PedidoCompraDetailScreen({super.key, required this.item});
  @override
  State<PedidoCompraDetailScreen> createState() => _State();
}

class _State extends State<PedidoCompraDetailScreen> {
  int _tab = 0;

  // Dados do pedido
  PedidoCompra? _pedido;
  bool _isLoading = true;
  String? _loadingError;

  // Dropdowns
  List<Map<String, dynamic>> _fornecedores = [];
  List<Map<String, dynamic>> _centrosCusto = [];

  // Controllers cabeçalho
  final _numeroCtrl = TextEditingController();
  final _observacaoCtrl = TextEditingController();
  final _descontoGeralCtrl = TextEditingController();

  String? _statusVal;
  String? _fornecedorId;
  String? _centroCustoId;
  DateTime? _dataEmissao;
  DateTime? _dataEntrega;

  bool get _isNovo => widget.item['id'] == null;
  String get _pedidoId => widget.item['id']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    _loadDropdowns();
    if (!_isNovo) {
      _loadPedido();
    } else {
      _initNovopedido();
    }
  }

  void _initNovopedido() {
    setState(() {
      _isLoading = false;
      _statusVal = 'RASCUNHO';
      _dataEmissao = DateTime.now();
      _dataEntrega = DateTime.now().add(const Duration(days: 15));
    });
  }

  Future<void> _loadDropdowns() async {
    final login = AuthUtility.userInfo?.login;
    final empId = login?.empresa?.id?.toString();

    await Future.wait([
      _loadList('${ApiLinks.baseUrl}/api/parceiro?tamanho=500${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _fornecedores = d)),
      _loadList('${ApiLinks.baseUrl}/api/centro_custo?tamanho=100${empId != null ? '&empId=$empId' : ''}',
          (d) => setState(() => _centrosCusto = d)),
    ]);
  }

  Future<void> _loadList(String url, void Function(List<Map<String, dynamic>>) cb) async {
    try {
      final r = await TenantContext.get(url);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        List raw = [];
        if (b is List) {
          raw = b;
        } else if (b is Map) {
          final data = b['data'];
          if (data is List) {
            raw = data;
          } else if (data is Map) {
            raw = data['dados'] ?? data['content'] ?? data['items'] ?? [];
          } else {
            raw = b['dados'] ?? b['content'] ?? b['items'] ?? [];
          }
        }
        cb(raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList());
      }
    } catch (_) {}
  }

  Future<void> _loadPedido() async {
    try {
      final r = await TenantContext.get('${ApiLinks.baseUrl}/api/pedido-compra/$_pedidoId');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is Map ? (b['data'] ?? b) : b;
        final pedido = PedidoCompra.fromJson(Map<String, dynamic>.from(data));
        setState(() {
          _pedido = pedido;
          _numeroCtrl.text = pedido.numero ?? '';
          _statusVal = pedido.status ?? 'RASCUNHO';
          _fornecedorId = pedido.fornecedorId?.toString();
          _centroCustoId = pedido.centroCustoId?.toString();
          _observacaoCtrl.text = pedido.observacao ?? '';
          _descontoGeralCtrl.text = pedido.descontoGeral?.toString() ?? '';
          _dataEmissao = pedido.dataEmissao != null ? DateTime.parse(pedido.dataEmissao!) : DateTime.now();
          _dataEntrega = pedido.dataEntrega != null ? DateTime.parse(pedido.dataEntrega!) : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _loadingError = 'Erro ${r.statusCode} ao carregar pedido';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _loadingError = 'Erro: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _salvar() async {
    if (_numeroCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Número é obrigatório'), backgroundColor: _red));
      return;
    }
    if (_fornecedorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fornecedor é obrigatório'), backgroundColor: _red));
      return;
    }

    final payload = {
      'numero': _numeroCtrl.text,
      'fornecedorId': int.tryParse(_fornecedorId ?? ''),
      'centroCustoId': int.tryParse(_centroCustoId ?? ''),
      'dataEmissao': _dataEmissao?.toIso8601String().substring(0, 10),
      'dataEntrega': _dataEntrega?.toIso8601String().substring(0, 10),
      'observacao': _observacaoCtrl.text,
      'descontoGeral': double.tryParse(_descontoGeralCtrl.text.replaceAll(',', '.')),
      'status': _statusVal,
      'itens': _pedido?.itens?.map((i) => i.toJson()).toList() ?? [],
    };

    try {
      final url = _isNovo
          ? '${ApiLinks.baseUrl}/api/pedido-compra'
          : '${ApiLinks.baseUrl}/api/pedido-compra/$_pedidoId';
      final method = _isNovo ? 'POST' : 'PUT';

      final r = method == 'POST'
          ? await TenantContext.post(url, payload)
          : await TenantContext.put(url, payload);

      if (!mounted) return;
      if (r.statusCode == 200 || r.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pedido salvo com sucesso!'), backgroundColor: _green));
        if (_isNovo) {
          Navigator.pop(context, true);
        }
      } else {
        String msg = 'Erro ${r.statusCode}';
        try {
          final body = jsonDecode(r.body);
          msg = body['message']?.toString() ?? body['mensagem']?.toString() ?? body['error']?.toString() ?? msg;
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: _red));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: _red));
    }
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _observacaoCtrl.dispose();
    _descontoGeralCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido de Compra'), backgroundColor: _red),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadingError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedido de Compra'), backgroundColor: _red),
        body: Center(child: Text(_loadingError!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedido de Compra'),
        backgroundColor: _red,
        actions: [
          _appBarBtn(Icons.save, 'Salvar', _salvar),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [
        _cabecalho(),
        Container(height: 1, color: _bord),
        _tabButtons(),
        Container(height: 1, color: _bord),
        Expanded(child: _tabContent()),
      ]),
    );
  }

  Widget _cabecalho() => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: _field('Número', _numeroCtrl, enabled: _isNovo)),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdown(
                label: 'Status',
                value: _statusVal,
                items: {
                  'RASCUNHO': 'Rascunho',
                  'EMITIDO': 'Emitido',
                  'APROVADO': 'Aprovado',
                  'RECEBIDO_PARCIAL': 'Recebido Parcial',
                  'RECEBIDO_TOTAL': 'Recebido Total',
                  'CANCELADO': 'Cancelado',
                },
                onChanged: (v) => setState(() => _statusVal = v),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: _dropdownList(
                label: 'Fornecedor',
                value: _fornecedorId,
                items: _fornecedores,
                displayField: 'nome',
                onChanged: (v) => setState(() => _fornecedorId = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _dropdownList(
                label: 'Centro de Custo',
                value: _centroCustoId,
                items: _centrosCusto,
                displayField: 'nome',
                onChanged: (v) => setState(() => _centroCustoId = v),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _datePicker('Data Emissão', _dataEmissao, (d) => setState(() => _dataEmissao = d))),
            const SizedBox(width: 8),
            Expanded(child: _datePicker('Data Entrega', _dataEntrega, (d) => setState(() => _dataEntrega = d))),
          ]),
          const SizedBox(height: 8),
          _field('Observação', _observacaoCtrl, maxLines: 2),
          const SizedBox(height: 8),
          _field('Desconto Geral', _descontoGeralCtrl),
          const SizedBox(height: 12),
          // Resumo
          if (_pedido != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _bg, border: Border.all(color: _bord)),
              child: Row(children: [
                _card('Total', (_pedido?.totalGeral ?? 0).toStringAsFixed(2)),
                const SizedBox(width: 8),
                _card('Itens', '${_pedido?.itens?.length ?? 0}'),
              ]),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _tabButtons() => Container(
    color: Colors.white,
    child: Row(
      children: [
        _tabBtn(0, 'Itens (${_pedido?.itens?.length ?? 0})'),
        _tabBtn(1, 'Histórico (${_pedido?.historico?.length ?? 0})'),
      ],
    ),
  );

  Widget _tabBtn(int idx, String label) {
    final on = _tab == idx;
    return GestureDetector(
      onTap: () => setState(() => _tab = idx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          border: Border(bottom: BorderSide(color: on ? _red : Colors.transparent, width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: on ? FontWeight.bold : FontWeight.normal,
            color: on ? _red : _grey,
          ),
        ),
      ),
    );
  }

  Widget _tabContent() {
    switch (_tab) {
      case 0:
        return _itensTab();
      case 1:
        return _historicoTab();
      default:
        return const SizedBox();
    }
  }

  Widget _itensTab() {
    final itens = _pedido?.itens ?? [];
    if (itens.isEmpty) {
      return const Center(child: Text('Nenhum item adicionado', style: TextStyle(color: _grey)));
    }
    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: [
            const DataColumn(label: Text('Produto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('Qtd', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true),
            const DataColumn(label: Text('Qtd. Recebida', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true),
            const DataColumn(label: Text('V. Unitário', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true),
            const DataColumn(label: Text('Desconto', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true),
            const DataColumn(label: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), numeric: true),
          ],
          rows: itens.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.produtoNome ?? '', style: const TextStyle(fontSize: 11))),
                DataCell(Text((item.quantidade ?? 0).toString(), style: const TextStyle(fontSize: 11))),
                DataCell(Text((item.quantidadeRecebida ?? 0).toString(), style: const TextStyle(fontSize: 11))),
                DataCell(Text((item.valorUnitario ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                DataCell(Text((item.desconto ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                DataCell(Text((item.total ?? 0).toStringAsFixed(2), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _historicoTab() {
    final historico = _pedido?.historico ?? [];
    if (historico.isEmpty) {
      return const Center(child: Text('Nenhum histórico', style: TextStyle(color: _grey)));
    }
    return ListView.builder(
      itemCount: historico.length,
      itemBuilder: (context, idx) {
        final h = historico[idx];
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _bord))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${h.statusAnterior} → ${h.statusNovo}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(h.data ?? '', style: const TextStyle(color: _grey, fontSize: 11)),
                ],
              ),
              if (h.observacao != null && h.observacao!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(h.observacao!, style: const TextStyle(color: _dark, fontSize: 11)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1, bool enabled = true}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: ctrl,
          enabled: enabled,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 12, color: _dark),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(fontSize: 11, color: _grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
        ),
      );

  Widget _dropdown(
    {required String label,
    required String? value,
    required Map<String, String> items,
    required Function(String?) onChanged}
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField(
      value: value,
      items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 11)))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: _grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    ),
  );

  Widget _dropdownList(
    {required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required String displayField,
    required Function(String?) onChanged}
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: DropdownButtonFormField(
      value: value,
      items: items.map((e) {
        final id = e['id']?.toString();
        final display = e[displayField]?.toString() ?? '';
        return DropdownMenuItem(value: id, child: Text(display, style: const TextStyle(fontSize: 11)));
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11, color: _grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
    ),
  );

  Widget _datePicker(String label, DateTime? value, Function(DateTime) onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) onChanged(d);
          },
          child: AbsorbPointer(
            child: TextFormField(
              style: const TextStyle(fontSize: 12, color: _dark),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(fontSize: 11, color: _grey),
                hintText: value?.toIso8601String().substring(0, 10) ?? '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: _bord)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
            ),
          ),
        ),
      );

  Widget _card(String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _bord)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: _grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _dark)),
      ],
    ),
  );

  Widget _appBarBtn(IconData icon, String label, VoidCallback onTap) =>
      TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
      );
}

import 'package:flutter/material.dart';
import '../../../models/auth_utility.dart';
import '../../../services/lancamento_contabil_service.dart';

const _primary = Color(0xFF93070A); // GridColors.primary
const _bg = Color(0xFFF5F5F5);
const _green = Color(0xFF005826);
const _red = Color(0xFF93070A);
const _border = Color(0xFFDDDDDD);

class WebBalanceteScreen extends StatefulWidget {
  const WebBalanceteScreen({super.key});
  @override
  State<WebBalanceteScreen> createState() => _WebBalanceteScreenState();
}

class _WebBalanceteScreenState extends State<WebBalanceteScreen>
    with SingleTickerProviderStateMixin {
  final _service = LancamentoContabilService();
  late final TabController _tabController;
  int _tab = 0;
  String _periodo = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';
  List<Map<String, dynamic>> _linhas = [];
  List<Map<String, dynamic>> _balanco = [];
  Map<String, dynamic>? _variacao;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final login = AuthUtility.userInfo?.login;
    final empId = int.tryParse(login?.empresa?.id?.toString() ?? '');
    if (empId == null) return;
    setState(() => _loading = true);
    try {
      if (_tab == 0) {
        final inicio = '$_periodo-01';
        final fim = '$_periodo-28';
        _linhas = await _service.balancete(empId, inicio, fim) ?? [];
      } else if (_tab == 1) {
        _balanco = await _service.balanco(empId, '$_periodo-28') ?? [];
      } else {
        _variacao = await _service.analisarVariacao(empId, _periodo, null);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Balancete / Balanço'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        actions: [
          SizedBox(
            width: 180,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Período (yyyy-MM)',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white12,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                controller: TextEditingController(text: _periodo),
                onSubmitted: (v) { _periodo = v; _carregar(); },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _carregar),
        ],
      ),
      body: Column(children: [
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Balancete'),
            Tab(text: 'Balanço Patrimonial'),
            Tab(text: 'Variação'),
          ],
          onTap: (i) { setState(() => _tab = i); _carregar(); },
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _tab == 0 ? _balanceteTab()
            : _tab == 1 ? _balancoTab()
            : _variacaoTab()),
      ]),
    );
  }

  Widget _balanceteTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        DataTable(columns: const [
          DataColumn(label: Text('Conta')),
          DataColumn(label: Text('Descrição')),
          DataColumn(label: Text('Débito'), numeric: true),
          DataColumn(label: Text('Crédito'), numeric: true),
          DataColumn(label: Text('Saldo'), numeric: true),
        ], rows: _linhas.map((l) => DataRow(cells: [
          DataCell(Text(l['codigo']?.toString() ?? '')),
          DataCell(Text(l['descricao']?.toString() ?? '')),
          DataCell(Text(_fmt(l['debito']))),
          DataCell(Text(_fmt(l['credito']))),
          DataCell(Text(_fmt(l['saldo']), style: TextStyle(
            fontWeight: FontWeight.bold,
            color: (l['saldo'] is num && (l['saldo'] as num) >= 0) ? _green : _red,
          ))),
        ])).toList()),
      ]),
    );
  }

  Widget _balancoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        DataTable(columns: const [
          DataColumn(label: Text('Grupo')),
          DataColumn(label: Text('Total'), numeric: true),
        ], rows: _balanco.map((l) => DataRow(cells: [
          DataCell(Text(l['grupo']?.toString() ?? '')),
          DataCell(Text(_fmt(l['total']))),
        ])).toList()),
      ]),
    );
  }

  Widget _variacaoTab() {
    if (_variacao == null) return const Center(child: Text('Sem dados'));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _card('Receita', _fmt(_variacao!['receita'])),
        _card('Despesa', _fmt(_variacao!['despesa'])),
        _card('Resultado', _fmt(_variacao!['resultado']),
            color: (_variacao!['resultado'] is num && (_variacao!['resultado'] as num) >= 0) ? _green : _red),
        if (_variacao!['variacaoReceitaPct'] != null)
          _card('Variação Receita', '${_variacao!['variacaoReceitaPct']}%'),
        if (_variacao!['variacaoDespesaPct'] != null)
          _card('Variação Despesa', '${_variacao!['variacaoDespesaPct']}%'),
      ]),
    );
  }

  Widget _card(String label, String valor, {Color? color}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '0,00';
    if (v is double || v is int) {
      return v.toStringAsFixed(2).replaceAll('.', ',');
    }
    return v.toString();
  }
}

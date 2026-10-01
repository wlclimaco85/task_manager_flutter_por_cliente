import 'package:flutter/material.dart';
import '../../../services/renegociacao_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/grid_texts.dart';

class RenegociacaoScreen extends StatefulWidget {
  const RenegociacaoScreen({super.key});

  @override
  State<RenegociacaoScreen> createState() => _RenegociacaoScreenState();
}

class _RenegociacaoScreenState extends State<RenegociacaoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _acordos = [];
  bool _loadingAcordos = false;

  final _tipoCtrl = TextEditingController();
  final _tituloIdCtrl = TextEditingController();
  final _novoValorCtrl = TextEditingController();
  final _jurosCtrl = TextEditingController();
  final _multaCtrl = TextEditingController();
  final _descontoCtrl = TextEditingController();
  final _parcelasCtrl = TextEditingController(text: '1');
  final _detalheIdCtrl = TextEditingController();
  Map<String, dynamic> _detalhe = {};
  bool _loadingDetalhe = false;
  bool _criando = false;

  final _tipos = ['Pagar', 'Receber'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _carregarAcordos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tipoCtrl.dispose();
    _tituloIdCtrl.dispose();
    _novoValorCtrl.dispose();
    _jurosCtrl.dispose();
    _multaCtrl.dispose();
    _descontoCtrl.dispose();
    _parcelasCtrl.dispose();
    _detalheIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarAcordos() async {
    setState(() => _loadingAcordos = true);
    final data = await RenegociacaoCaller.listar();
    if (mounted) setState(() { _acordos = data; _loadingAcordos = false; });
  }

  Future<void> _criarAcordo() async {
    if (_tipoCtrl.text.isEmpty || _tituloIdCtrl.text.isEmpty || _novoValorCtrl.text.isEmpty) {
      _snack('Preencha Tipo, Título Original ID e Novo Valor', error: true);
      return;
    }
    setState(() => _criando = true);
    final body = <String, dynamic>{
      'tipo': _tipoCtrl.text,
      'tituloOriginalId': int.tryParse(_tituloIdCtrl.text),
      'novoValor': double.tryParse(_novoValorCtrl.text),
      'numeroParcelas': int.tryParse(_parcelasCtrl.text) ?? 1,
    };
    if (_jurosCtrl.text.isNotEmpty) body['juros'] = double.tryParse(_jurosCtrl.text);
    if (_multaCtrl.text.isNotEmpty) body['multa'] = double.tryParse(_multaCtrl.text);
    if (_descontoCtrl.text.isNotEmpty) body['desconto'] = double.tryParse(_descontoCtrl.text);

    final result = await RenegociacaoCaller.criar(body);
    if (mounted) {
      setState(() => _criando = false);
      _snack(result['success'] ? 'Acordo criado com sucesso' : result['message'],
          error: !result['success']);
      if (result['success']) {
        _tituloIdCtrl.clear();
        _novoValorCtrl.clear();
        _jurosCtrl.clear();
        _multaCtrl.clear();
        _descontoCtrl.clear();
        _parcelasCtrl.text = '1';
        _carregarAcordos();
      }
    }
  }

  Future<void> _buscarDetalhe() async {
    final id = _detalheIdCtrl.text.trim();
    if (id.isEmpty) { _snack('Informe o ID do acordo', error: true); return; }
    setState(() => _loadingDetalhe = true);
    final data = await RenegociacaoCaller.buscarPorId(id);
    if (mounted) setState(() { _detalhe = data; _loadingDetalhe = false; });
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? GridColors.error : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Renegociação de Títulos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Acordos'),
            Tab(text: 'Novo Acordo'),
            Tab(text: 'Detalhe'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAcordosTab(),
          _buildNovoAcordoTab(),
          _buildDetalheTab(),
        ],
      ),
    );
  }

  Widget _buildAcordosTab() {
    if (_loadingAcordos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_acordos.isEmpty) {
      return const Center(child: Text('Nenhum acordo encontrado'));
    }
    return RefreshIndicator(
      onRefresh: _carregarAcordos,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _acordos.length,
        itemBuilder: (_, i) {
          final a = _acordos[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              title: Text('Acordo #${a['id'] ?? ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cliente/Fornecedor: ${a['cliente'] ?? a['fornecedor'] ?? '-'}'),
                  Text('Valor Original: R\$ ${_fmt(a['valorOriginal'])}'),
                  Text('Novo Valor: R\$ ${_fmt(a['novoValor'])}'),
                  Text('Parcelas: ${a['numeroParcelas'] ?? '-'}'),
                  Text('Status: ${a['status'] ?? '-'}'),
                ],
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }

  Widget _buildNovoAcordoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Tipo'),
            value: _tipoCtrl.text.isEmpty ? null : _tipoCtrl.text,
            items: _tipos.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => _tipoCtrl.text = v ?? '',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tituloIdCtrl,
            decoration: const InputDecoration(labelText: 'Título Original ID'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _novoValorCtrl,
            decoration: const InputDecoration(labelText: 'Novo Valor'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _jurosCtrl,
            decoration: const InputDecoration(labelText: 'Juros'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _multaCtrl,
            decoration: const InputDecoration(labelText: 'Multa'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descontoCtrl,
            decoration: const InputDecoration(labelText: 'Desconto'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _parcelasCtrl,
            decoration: const InputDecoration(labelText: 'Número de Parcelas'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _criando ? null : _criarAcordo,
            child: _criando
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Criar Acordo'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalheTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _detalheIdCtrl,
                  decoration: const InputDecoration(labelText: 'Acordo ID'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadingDetalhe ? null : _buscarDetalhe,
                child: const Text(GridTexts.search),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingDetalhe)
            const Center(child: CircularProgressIndicator())
          else if (_detalhe.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${_detalhe['id'] ?? '-'}'),
                    Text('Tipo: ${_detalhe['tipo'] ?? '-'}'),
                    Text('Cliente/Fornecedor: ${_detalhe['cliente'] ?? _detalhe['fornecedor'] ?? '-'}'),
                    Text('Valor Original: R\$ ${_fmt(_detalhe['valorOriginal'])}'),
                    Text('Novo Valor: R\$ ${_fmt(_detalhe['novoValor'])}'),
                    Text('Juros: ${_fmt(_detalhe['juros'])}'),
                    Text('Multa: ${_fmt(_detalhe['multa'])}'),
                    Text('Desconto: ${_fmt(_detalhe['desconto'])}'),
                    Text('Parcelas: ${_detalhe['numeroParcelas'] ?? '-'}'),
                    Text('Status: ${_detalhe['status'] ?? '-'}'),
                    if (_detalhe['parcelas'] != null) ...[
                      const SizedBox(height: 8),
                      const Text('Parcelas:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ...(_detalhe['parcelas'] as List).map((p) => Text(
                        '  #${p['numero'] ?? '-'} - R\$ ${_fmt(p['valor'])} - ${p['vencimento'] ?? '-'} - ${p['status'] ?? '-'}',
                      )),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    if (v is num) return v.toStringAsFixed(2);
    return v.toString();
  }
}

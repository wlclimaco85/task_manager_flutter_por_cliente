import 'package:flutter/material.dart';
import '../../../services/cobranca_caller.dart';
import '../../../utils/grid_colors.dart';
import '../../utils/grid_texts.dart';

class CobrancaScreen extends StatefulWidget {
  const CobrancaScreen({super.key});

  @override
  State<CobrancaScreen> createState() => _CobrancaScreenState();
}

class _CobrancaScreenState extends State<CobrancaScreen> {
  List<dynamic> _vencidos = [];
  List<dynamic> _regras = [];
  List<dynamic> _acoes = [];
  bool _loadingVencidos = false;
  bool _loadingRegras = false;
  bool _loadingAcoes = false;
  bool _executandoRegua = false;
  final TextEditingController _clienteIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarVencidos();
    _carregarRegras();
  }

  @override
  void dispose() {
    _clienteIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarVencidos() async {
    setState(() => _loadingVencidos = true);
    final data = await CobrancaCaller.listarVencidos();
    if (mounted) setState(() { _vencidos = data; _loadingVencidos = false; });
  }

  Future<void> _carregarRegras() async {
    setState(() => _loadingRegras = true);
    final data = await CobrancaCaller.listarRegras();
    if (mounted) setState(() { _regras = data; _loadingRegras = false; });
  }

  Future<void> _executarRegua() async {
    setState(() => _executandoRegua = true);
    final result = await CobrancaCaller.executarRegua();
    if (mounted) {
      setState(() => _executandoRegua = false);
      _snack(result['success'] ? GridTexts.collectionRuleExecutedSuccess : result['message'],
          error: !result['success']);
      if (result['success']) _carregarVencidos();
    }
  }

  Future<void> _buscarAcoes() async {
    final id = int.tryParse(_clienteIdCtrl.text);
    if (id == null) { _snack(GridTexts.invalidClientId, error: true); return; }
    setState(() => _loadingAcoes = true);
    final data = await CobrancaCaller.listarAcoesCliente(id);
    if (mounted) setState(() { _acoes = data; _loadingAcoes = false; });
  }

  void _novaRegra() { _abrirRegraDialog(); }

  void _editarRegra(dynamic regra) { _abrirRegraDialog(regra: regra); }

  Future<void> _deletarRegra(dynamic regra) async {
    final id = regra['id']?.toString();
    if (id == null) return;
    final ok = await CobrancaCaller.deletarRegra(id);
    if (mounted) {
      _snack(ok ? GridTexts.collectionRuleRemoved : GridTexts.removeError, error: !ok);
      if (ok) _carregarRegras();
    }
  }

  void _abrirRegraDialog({dynamic regra}) {
    final isEdit = regra != null;
    final diasInicioCtrl = TextEditingController(text: isEdit ? '${regra['diasInicio'] ?? ''}' : '');
    final diasFimCtrl = TextEditingController(text: isEdit ? '${regra['diasFim'] ?? ''}' : '');
    final acaoCtrl = TextEditingController(text: isEdit ? regra['acao'] ?? '' : '');
    final mensagemCtrl = TextEditingController(text: isEdit ? regra['mensagem'] ?? '' : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Editar Regra' : 'Nova Regra'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: diasInicioCtrl,
                decoration: const InputDecoration(labelText: 'Dias Início'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: diasFimCtrl,
                decoration: const InputDecoration(labelText: 'Dias Fim'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: acaoCtrl,
                decoration: const InputDecoration(labelText: 'Ação'),
              ),
              TextField(
                controller: mensagemCtrl,
                decoration: const InputDecoration(labelText: 'Mensagem'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'diasInicio': int.tryParse(diasInicioCtrl.text) ?? 0,
                'diasFim': int.tryParse(diasFimCtrl.text) ?? 0,
                'acao': acaoCtrl.text,
                'mensagem': mensagemCtrl.text,
              };
              final result = await CobrancaCaller.salvarRegra(data, id: isEdit ? regra['id']?.toString() : null);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                _snack(result['success'] ? GridTexts.collectionRuleSaved : result['message'], error: !result['success']);
                if (result['success']) _carregarRegras();
              }
            },
            child: Text(isEdit ? GridTexts.update : GridTexts.create),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? GridColors.error : GridColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            height: 56,
            color: GridColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.money_off, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                const Text('Inadimplência e Cobrança',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: _executandoRegua
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.play_arrow, color: Colors.white),
                  tooltip: GridTexts.executeRule,
                  onPressed: _executandoRegua ? null : _executarRegua,
                ),
                const TabBar(
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: [
                    Tab(text: 'Vencidos'),
                    Tab(text: 'Ações'),
                    Tab(text: 'Régua'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildVencidosTab(),
                _buildAcoesTab(),
                _buildReguaTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVencidosTab() {
    if (_loadingVencidos) return const Center(child: CircularProgressIndicator());
    if (_vencidos.isEmpty) return const Center(child: Text(GridTexts.noOverdueFound));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Cliente')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Dias Atraso')),
          DataColumn(label: Text('Ações')),
        ],
        rows: _vencidos.map((v) {
          final nome = v['cliente'] ?? v['nome'] ?? v['clienteNome'] ?? '-';
          final valor = v['valor'] ?? v['valorTotal'] ?? 0;
          final dias = v['diasAtraso'] ?? v['dias'] ?? 0;
          return DataRow(cells: [
            DataCell(Text('$nome')),
            DataCell(Text('R\$ ${_fmtValor(valor)}')),
            DataCell(Text('$dias')),
            DataCell(Text(v['acao'] ?? '-')),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildAcoesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _clienteIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ID do Cliente',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    fillColor: GridColors.textPrimary,
                    filled: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _buscarAcoes,
                child: const Text(GridTexts.search),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loadingAcoes
                ? const Center(child: CircularProgressIndicator())
                : _acoes.isEmpty
                    ? const Center(child: Text(GridTexts.noActionFound))
                    : ListView.builder(
                        itemCount: _acoes.length,
                        itemBuilder: (_, i) {
                          final a = _acoes[i];
                          return Card(
                            child: ListTile(
                              title: Text('${a['acao'] ?? '-'}'),
                              subtitle: Text(a['mensagem'] ?? a['descricao'] ?? ''),
                              trailing: Text(a['data'] ?? ''),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReguaTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              const Text('Regras da Régua de Cobrança', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _novaRegra,
                icon: const Icon(Icons.add, size: 18),
                label: const Text(GridTexts.newLabel),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loadingRegras
              ? const Center(child: CircularProgressIndicator())
              : _regras.isEmpty
                  ? const Center(child: Text(GridTexts.noRuleRegistered))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _regras.length,
                      itemBuilder: (_, i) {
                        final r = _regras[i];
                        return Card(
                          child: ListTile(
                            title: Text('${r['acao'] ?? '-'} (${r['diasInicio'] ?? 0}-${r['diasFim'] ?? 0} dias)'),
                            subtitle: Text(r['mensagem'] ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editarRegra(r)),
                                IconButton(icon: const Icon(Icons.delete, size: 20, color: GridColors.error), onPressed: () => _deletarRegra(r)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  String _fmtValor(dynamic v) {
    if (v == null) return '0,00';
    final n = v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    return n.toStringAsFixed(2).replaceAll('.', ',');
  }
}

import 'package:flutter/material.dart';
import '../../services/deposito_caller.dart';
import '../../utils/grid_texts.dart';

class DepositoScreen extends StatefulWidget {
  const DepositoScreen({super.key});

  @override
  State<DepositoScreen> createState() => _DepositoScreenState();
}

class _DepositoScreenState extends State<DepositoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-depósito e Localização'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Depósitos'),
            Tab(text: 'Localizações'),
            Tab(text: 'Saldo'),
            Tab(text: 'Transferir'),
            Tab(text: 'Ajustar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DepositosTab(),
          _LocalizacoesTab(),
          _SaldoTab(),
          _TransferirTab(),
          _AjustarTab(),
        ],
      ),
    );
  }
}

// ─── Aba Depósitos ─────────────────────────────────────────────────────────

class _DepositosTab extends StatefulWidget {
  const _DepositosTab();
  @override
  State<_DepositosTab> createState() => _DepositosTabState();
}

class _DepositosTabState extends State<_DepositosTab> {
  List<Map<String, dynamic>> _depositos = [];
  bool _loading = false;

  final _nomeCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();
  bool _ativo = true;
  int? _editandoId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final data = await DepositoCaller.listarDepositos();
    if (mounted) setState(() { _depositos = data; _loading = false; });
  }

  void _limparForm() {
    _nomeCtrl.clear();
    _codigoCtrl.clear();
    _ativo = true;
    _editandoId = null;
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    final codigo = _codigoCtrl.text.trim();
    if (nome.isEmpty) return;
    final body = <String, dynamic>{'nome': nome, 'codigo': codigo, 'ativo': _ativo};
    final ok = _editandoId == null
        ? await DepositoCaller.criarDeposito(body)
        : await DepositoCaller.atualizarDeposito(_editandoId!, body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Depósito salvo' : 'Erro ao salvar'),
      ));
      if (ok) { _limparForm(); _carregar(); }
    }
  }

  Future<void> _deletar(int id) async {
    final ok = await DepositoCaller.deletarDeposito(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Depósito removido' : 'Erro ao remover'),
      ));
      if (ok) _carregar();
    }
  }

  void _editar(Map<String, dynamic> d) {
    _nomeCtrl.text = d['nome'] ?? '';
    _codigoCtrl.text = d['codigo'] ?? '';
    _ativo = d['ativo'] ?? true;
    _editandoId = d['id'];
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nomeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nome', border: OutlineInputBorder(), isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _codigoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Código', border: OutlineInputBorder(), isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: [
                  const Text('Ativo'),
                  Switch(
                    value: _ativo,
                    onChanged: (v) => setState(() => _ativo = v),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _salvar,
                child: Text(_editandoId == null ? 'Adicionar' : 'Atualizar'),
              ),
              if (_editandoId != null)
                TextButton(
                  onPressed: () { _limparForm(); setState(() {}); },
                  child: const Text(GridTexts.cancel),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _depositos.isEmpty
                    ? const Center(child: Text('Nenhum depósito cadastrado'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Nome')),
                            DataColumn(label: Text('Código')),
                            DataColumn(label: Text('Ativo')),
                            DataColumn(label: Text('Ações')),
                          ],
                          rows: _depositos.map((d) {
                            final id = d['id'] ?? 0;
                            return DataRow(cells: [
                              DataCell(Text('$id')),
                              DataCell(Text('${d['nome'] ?? '-'}')),
                              DataCell(Text('${d['codigo'] ?? '-'}')),
                              DataCell(Text(d['ativo'] == true ? 'Sim' : 'Não')),
                              DataCell(Row(
                                children: [
                                  TextButton(
                                    onPressed: () => _editar(d),
                                    child: const Text('Editar'),
                                  ),
                                  TextButton(
                                    onPressed: () => _deletar(id is int ? id : int.tryParse('$id') ?? 0),
                                    child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Localizações ─────────────────────────────────────────────────────

class _LocalizacoesTab extends StatefulWidget {
  const _LocalizacoesTab();
  @override
  State<_LocalizacoesTab> createState() => _LocalizacoesTabState();
}

class _LocalizacoesTabState extends State<_LocalizacoesTab> {
  List<Map<String, dynamic>> _depositos = [];
  List<Map<String, dynamic>> _localizacoes = [];
  int? _depositoSelecionado;
  bool _loadingDepositos = false;
  bool _loadingLocalizacoes = false;

  final _locCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _carregarDepositos();
  }

  @override
  void dispose() {
    _locCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDepositos() async {
    setState(() => _loadingDepositos = true);
    final data = await DepositoCaller.listarDepositos();
    if (mounted) setState(() { _depositos = data; _loadingDepositos = false; });
  }

  Future<void> _carregarLocalizacoes() async {
    if (_depositoSelecionado == null) return;
    setState(() => _loadingLocalizacoes = true);
    final data = await DepositoCaller.listarLocalizacoes(_depositoSelecionado!);
    if (mounted) setState(() { _localizacoes = data; _loadingLocalizacoes = false; });
  }

  Future<void> _adicionarLocalizacao() async {
    final nome = _locCtrl.text.trim();
    if (nome.isEmpty || _depositoSelecionado == null) return;
    final ok = await DepositoCaller.criarLocalizacao(_depositoSelecionado!, {'nome': nome});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Localização adicionada' : 'Erro ao adicionar'),
      ));
      if (ok) { _locCtrl.clear(); _carregarLocalizacoes(); }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Depósito: '),
              const SizedBox(width: 8),
              SizedBox(
                width: 250,
                child: _loadingDepositos
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<int>(
                        value: _depositoSelecionado,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(), isDense: true,
                        ),
                        hint: const Text('Selecione um depósito'),
                        items: _depositos.map((d) {
                          final id = d['id'] ?? 0;
                          return DropdownMenuItem(
                            value: id is int ? id : int.tryParse('$id'),
                            child: Text('${d['nome'] ?? '-'}'),
                          );
                        }).toList(),
                        onChanged: (v) {
                          setState(() => _depositoSelecionado = v);
                          _carregarLocalizacoes();
                        },
                      ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _locCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nova localização',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _adicionarLocalizacao,
                child: const Text('Adicionar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loadingLocalizacoes
                ? const Center(child: CircularProgressIndicator())
                : _localizacoes.isEmpty
                    ? const Center(child: Text('Nenhuma localização'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Nome')),
                          ],
                          rows: _localizacoes.map((l) {
                            return DataRow(cells: [
                              DataCell(Text('${l['id'] ?? 0}')),
                              DataCell(Text('${l['nome'] ?? '-'}')),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Saldo ────────────────────────────────────────────────────────────

class _SaldoTab extends StatefulWidget {
  const _SaldoTab();
  @override
  State<_SaldoTab> createState() => _SaldoTabState();
}

class _SaldoTabState extends State<_SaldoTab> {
  final _produtoIdCtrl = TextEditingController();
  List<Map<String, dynamic>> _saldos = [];
  bool _loading = false;

  @override
  void dispose() {
    _produtoIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    final id = int.tryParse(_produtoIdCtrl.text);
    if (id == null) return;
    setState(() { _loading = true; _saldos = []; });
    final data = await DepositoCaller.consultarSaldo(id);
    if (mounted) setState(() { _saldos = data; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _produtoIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Produto ID',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _consultar,
                child: const Text('Consultar Saldo'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _saldos.isEmpty
                    ? const Center(child: Text('Nenhum saldo encontrado'))
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Depósito')),
                            DataColumn(label: Text('Quantidade')),
                          ],
                          rows: _saldos.map((s) {
                            return DataRow(cells: [
                              DataCell(Text('${s['deposito'] ?? s['depositoNome'] ?? s['nome'] ?? '-'}')),
                              DataCell(Text('${s['quantidade'] ?? s['saldo'] ?? s['qtd'] ?? 0}')),
                            ]);
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Aba Transferir ───────────────────────────────────────────────────────

class _TransferirTab extends StatefulWidget {
  const _TransferirTab();
  @override
  State<_TransferirTab> createState() => _TransferirTabState();
}

class _TransferirTabState extends State<_TransferirTab> {
  List<Map<String, dynamic>> _depositos = [];
  int? _origemId;
  int? _destinoId;
  final _produtoIdCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarDepositos();
  }

  @override
  void dispose() {
    _produtoIdCtrl.dispose();
    _quantidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDepositos() async {
    final data = await DepositoCaller.listarDepositos();
    if (mounted) setState(() => _depositos = data);
  }

  Future<void> _transferir() async {
    final produtoId = int.tryParse(_produtoIdCtrl.text);
    final quantidade = double.tryParse(_quantidadeCtrl.text);
    if (_origemId == null || _destinoId == null || produtoId == null || quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente')),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await DepositoCaller.transferir({
      'origemDepositoId': _origemId,
      'destinoDepositoId': _destinoId,
      'produtoId': produtoId,
      'quantidade': quantidade,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Transferência realizada' : 'Erro na transferência'),
      ));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _origemId,
                  decoration: const InputDecoration(
                    labelText: 'Depósito Origem',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  items: _depositos.map((d) {
                    final id = d['id'] ?? 0;
                    return DropdownMenuItem(
                      value: id is int ? id : int.tryParse('$id'),
                      child: Text('${d['nome'] ?? '-'}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _origemId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _destinoId,
                  decoration: const InputDecoration(
                    labelText: 'Depósito Destino',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  items: _depositos.map((d) {
                    final id = d['id'] ?? 0;
                    return DropdownMenuItem(
                      value: id is int ? id : int.tryParse('$id'),
                      child: Text('${d['nome'] ?? '-'}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _destinoId = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _produtoIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Produto ID',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _quantidadeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _transferir,
                child: const Text('Transferir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Aba Ajustar ──────────────────────────────────────────────────────────

class _AjustarTab extends StatefulWidget {
  const _AjustarTab();
  @override
  State<_AjustarTab> createState() => _AjustarTabState();
}

class _AjustarTabState extends State<_AjustarTab> {
  List<Map<String, dynamic>> _depositos = [];
  int? _depositoId;
  final _produtoIdCtrl = TextEditingController();
  final _quantidadeCtrl = TextEditingController();
  String _tipo = 'ENTRADA';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _carregarDepositos();
  }

  @override
  void dispose() {
    _produtoIdCtrl.dispose();
    _quantidadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDepositos() async {
    final data = await DepositoCaller.listarDepositos();
    if (mounted) setState(() => _depositos = data);
  }

  Future<void> _ajustar() async {
    final produtoId = int.tryParse(_produtoIdCtrl.text);
    final quantidade = double.tryParse(_quantidadeCtrl.text);
    if (_depositoId == null || produtoId == null || quantidade == null || quantidade <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos corretamente')),
      );
      return;
    }
    setState(() => _loading = true);
    final ok = await DepositoCaller.ajustar({
      'depositoId': _depositoId,
      'produtoId': produtoId,
      'tipo': _tipo,
      'quantidade': quantidade,
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? 'Ajuste realizado' : 'Erro no ajuste'),
      ));
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _depositoId,
                  decoration: const InputDecoration(
                    labelText: 'Depósito',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  items: _depositos.map((d) {
                    final id = d['id'] ?? 0;
                    return DropdownMenuItem(
                      value: id is int ? id : int.tryParse('$id'),
                      child: Text('${d['nome'] ?? '-'}'),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _depositoId = v),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _produtoIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Produto ID',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _quantidadeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(), isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: const InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(), isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'ENTRADA', child: Text('Entrada')),
                  DropdownMenuItem(value: 'SAIDA', child: Text('Saída')),
                ],
                onChanged: (v) => setState(() => _tipo = v!),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _loading ? null : _ajustar,
                child: const Text('Ajustar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

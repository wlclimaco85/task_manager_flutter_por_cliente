import 'package:flutter/material.dart';
import '../../services/rateio_caller.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../constants/custom_colors.dart';

class RateioFinanceiroScreen extends StatefulWidget {
  const RateioFinanceiroScreen({super.key});

  @override
  State<RateioFinanceiroScreen> createState() => _RateioFinanceiroScreenState();
}

class _RateioFinanceiroScreenState extends State<RateioFinanceiroScreen>
    with SingleTickerProviderStateMixin {
  final _lancamentoIdCtrl = TextEditingController();
  String _tipo = 'CONTA_PAGAR';
  late TabController _tabCtrl;

  List<_RateioItem> _itens = [];
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _centrosCusto = [];
  List<Map<String, dynamic>> _historico = [];
  bool _loading = false;
  bool _loadingDropdowns = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _carregarDropdowns();
  }

  @override
  void dispose() {
    _lancamentoIdCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarDropdowns() async {
    setState(() => _loadingDropdowns = true);
    try {
      final catRes =
          await NetworkCaller().getRequest(ApiLinks.allCategoriasFinanceiras);
      final ccRes =
          await NetworkCaller().getRequest(ApiLinks.allCentrosCusto);
      if (catRes.isSuccess && catRes.body != null) {
        _categorias = _extrairLista(catRes.body!);
      }
      if (ccRes.isSuccess && ccRes.body != null) {
        _centrosCusto = _extrairLista(ccRes.body!);
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingDropdowns = false);
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

  Future<void> _carregarItens() async {
    final id = _lancamentoIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await RateioCaller.listar(tipo: _tipo, id: id);
      if (res.isSuccess && res.body != null) {
        final lista = _extrairLista(res.body!);
        _itens = lista.map((j) => _RateioItem.fromJson(j)).toList();
      } else {
        _itens = [];
      }
    } catch (_) {
      _itens = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _carregarHistorico() async {
    final id = _lancamentoIdCtrl.text.trim();
    if (id.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await RateioCaller.historico(tipo: _tipo, id: id);
      if (res.isSuccess && res.body != null) {
        _historico = _extrairLista(res.body!);
      } else {
        _historico = [];
      }
    } catch (_) {
      _historico = [];
    }
    if (mounted) setState(() => _loading = false);
  }

  void _adicionarItem() {
    setState(() => _itens.add(_RateioItem()));
  }

  void _removerItem(int index) {
    setState(() => _itens.removeAt(index));
  }

  Future<void> _salvar() async {
    final id = _lancamentoIdCtrl.text.trim();
    if (id.isEmpty) return;
    if (!_validarPercentual()) return;

    setState(() => _loading = true);
    try {
      final body = {
        'lancamentoId': int.tryParse(id) ?? id,
        'lancamentoTipo': _tipo,
        'itens': _itens.map((i) => i.toJson()).toList(),
      };
      final res = await RateioCaller.salvar(body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor:
              res.isSuccess ? Colors.green : Colors.red,
          content: Text(res.isSuccess
              ? 'Rateio salvo com sucesso!'
              : 'Erro ao salvar rateio (${res.statusCode})'),
        ));
        if (res.isSuccess) {
          await _carregarItens();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text('Erro: $e'),
        ));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _validarPercentual() {
    if (_itens.isEmpty) return false;
    final total = _itens.fold<double>(
        0, (sum, i) => sum + (i.tipo == 'PERCENTUAL' ? (i.percentual ?? 0) : 0));
    if ((total - 100).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('A soma dos percentuais deve ser 100% (atual: ${total.toStringAsFixed(2)}%)'),
      ));
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colors = CustomColors();
    return Column(
      children: [
        Container(
          height: 56,
          color: GridColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.account_balance, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text('Rateio Financeiro',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              SizedBox(
                width: 280,
                child: TabBar(
                  controller: _tabCtrl,
                  onTap: (i) {
                    if (i == 1) _carregarHistorico();
                  },
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Rateio'),
                    Tab(text: 'Histórico'),
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
              _buildRateioTab(colors),
              _buildHistoricoTab(colors),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRateioTab(CustomColors colors) {
    return Column(
      children: [
        _buildFiltro(colors),
        const Divider(height: 1),
        Expanded(child: _buildTabela(colors)),
        _buildRodape(colors),
      ],
    );
  }

  Widget _buildFiltro(CustomColors colors) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: TextField(
              controller: _lancamentoIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Lançamento ID',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            child: DropdownButtonFormField<String>(
              value: _tipo,
              decoration: const InputDecoration(
                labelText: 'Tipo',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'CONTA_PAGAR', child: Text('Conta a Pagar')),
                DropdownMenuItem(value: 'CONTA_RECEBER', child: Text('Conta a Receber')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _tipo = v);
              },
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _loading ? null : _carregarItens,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Carregar Itens'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabela(CustomColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_itens.isEmpty) {
      return const Center(child: Text('Nenhum item. Clique em "Adicionar Item" para começar.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Categoria')),
          DataColumn(label: Text('Centro de Custo')),
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('% / Valor')),
          DataColumn(label: Text('Ações')),
        ],
        rows: List.generate(_itens.length, (i) => _buildLinha(i, colors)),
      ),
    );
  }

  DataRow _buildLinha(int i, CustomColors colors) {
    final item = _itens[i];
    return DataRow(cells: [
      DataCell(_dropdownCategoria(item, i)),
      DataCell(_dropdownCentroCusto(item, i)),
      DataCell(_dropdownTipoRateio(item, i)),
      DataCell(_buildValorField(item, i)),
      DataCell(IconButton(
        icon: Icon(Icons.delete, color: colors.getCancelButtonColor(), size: 20),
        onPressed: () => _removerItem(i),
      )),
    ]);
  }

  Widget _dropdownCategoria(_RateioItem item, int i) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        value: item.categoriaId,
        isDense: true,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        items: _categorias
            .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text(
                      '${c['descricao'] ?? c['nome'] ?? ''}'),
                ))
            .toList(),
        onChanged: (v) => setState(() => item.categoriaId = v),
      ),
    );
  }

  Widget _dropdownCentroCusto(_RateioItem item, int i) {
    return SizedBox(
      width: 160,
      child: DropdownButtonFormField<int>(
        value: item.centroCustoId,
        isDense: true,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        items: _centrosCusto
            .map((c) => DropdownMenuItem<int>(
                  value: c['id'] as int,
                  child: Text('${c['nome'] ?? ''}'),
                ))
            .toList(),
        onChanged: (v) => setState(() => item.centroCustoId = v),
      ),
    );
  }

  Widget _dropdownTipoRateio(_RateioItem item, int i) {
    return SizedBox(
      width: 130,
      child: DropdownButtonFormField<String>(
        value: item.tipo,
        isDense: true,
        decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
        items: const [
          DropdownMenuItem(value: 'PERCENTUAL', child: Text('%')),
          DropdownMenuItem(value: 'VALOR', child: Text('Valor')),
        ],
        onChanged: (v) {
          if (v != null) setState(() => item.tipo = v);
        },
      ),
    );
  }

  Widget _buildValorField(_RateioItem item, int i) {
    return SizedBox(
      width: 120,
      child: TextField(
        controller: TextEditingController(
          text: item.tipo == 'PERCENTUAL'
              ? item.percentual?.toStringAsFixed(2) ?? ''
              : item.valor?.toStringAsFixed(2) ?? '',
        ),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          isDense: true,
          suffixText: '%',
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) {
          final parsed = double.tryParse(v.replaceAll(',', '.'));
          if (item.tipo == 'PERCENTUAL') {
            item.percentual = parsed;
          } else {
            item.valor = parsed;
          }
        },
      ),
    );
  }

  Widget _buildRodape(CustomColors colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _adicionarItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar Item'),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: (_loading || _itens.isEmpty) ? null : _salvar,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Salvar Rateio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoTab(CustomColors colors) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_historico.isEmpty) {
      return const Center(child: Text('Nenhum histórico encontrado.'));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16,
        columns: const [
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Usuário')),
          DataColumn(label: Text('Ação')),
          DataColumn(label: Text('Detalhes')),
        ],
        rows: _historico.map((h) {
          return DataRow(cells: [
            DataCell(Text(h['data']?.toString() ?? h['createdAt']?.toString() ?? '')),
            DataCell(Text(h['usuario']?.toString() ?? h['userName']?.toString() ?? '')),
            DataCell(Text(h['acao']?.toString() ?? h['tipo']?.toString() ?? '')),
            DataCell(Text(h['detalhes']?.toString() ?? h['descricao']?.toString() ?? '')),
          ]);
        }).toList(),
      ),
    );
  }
}

class _RateioItem {
  int? categoriaId;
  int? centroCustoId;
  String tipo;
  double? percentual;
  double? valor;

  _RateioItem({
    this.categoriaId,
    this.centroCustoId,
    this.tipo = 'PERCENTUAL',
    this.percentual,
    this.valor,
  });

  factory _RateioItem.fromJson(Map<String, dynamic> json) {
    return _RateioItem(
      categoriaId: json['categoriaId'],
      centroCustoId: json['centroCustoId'],
      tipo: json['tipoRateio']?.toString() ?? 'PERCENTUAL',
      percentual: (json['percentual'] as num?)?.toDouble(),
      valor: (json['valor'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (categoriaId != null) 'categoriaId': categoriaId,
      if (centroCustoId != null) 'centroCustoId': centroCustoId,
      'tipoRateio': tipo,
      if (percentual != null) 'percentual': percentual,
      if (valor != null) 'valor': valor,
    };
  }
}

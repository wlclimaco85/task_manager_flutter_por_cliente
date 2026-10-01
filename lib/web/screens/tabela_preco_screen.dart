import 'package:flutter/material.dart';

import '../../services/tabela_preco_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType, CustomAction;
import '../../customization/dynamic_grid_windows_screen.dart';

class WebTabelaPrecoScreen extends StatefulWidget {
  final SecurityCheck hasPermission;

  const WebTabelaPrecoScreen({
    super.key,
    required this.hasPermission,
  });

  @override
  State<WebTabelaPrecoScreen> createState() => _WebTabelaPrecoScreenState();
}

class _WebTabelaPrecoScreenState extends State<WebTabelaPrecoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  Map<String, dynamic>? _tabelaSelecionada;
  List<Map<String, dynamic>> _tabelas = [];
  List<Map<String, dynamic>> _itens = [];
  bool _loadingTabelas = false;
  bool _loadingItens = false;
  int _itensGridKey = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _carregarTabelas();
    _tabCtrl.addListener(() {
      if (_tabCtrl.index == 1) _carregarTabelas();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregarTabelas() async {
    setState(() => _loadingTabelas = true);
    final res = await TabelaPrecoCaller.listarTabelas();
    if (res.isSuccess && res.body != null) {
      final lista = _extrairLista(res.body!);
      if (mounted) {
        setState(() {
          _tabelas = lista;
          _loadingTabelas = false;
        });
      }
    } else {
      if (mounted) setState(() => _loadingTabelas = false);
    }
  }

  Future<void> _carregarItens() async {
    if (_tabelaSelecionada == null) return;
    final id = _tabelaSelecionada!['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _loadingItens = true);
    final res = await TabelaPrecoCaller.listarItens(id);
    if (res.isSuccess && res.body != null) {
      final lista = _extrairLista(res.body!);
      if (mounted) {
        setState(() {
          _itens = lista;
          _loadingItens = false;
          _itensGridKey++;
        });
      }
    } else {
      if (mounted) setState(() => _loadingItens = false);
    }
  }

  List<Map<String, dynamic>> _extrairLista(Map<String, dynamic> body) {
    final data =
        body['data'] ?? body['dados'] ?? body['content'] ?? body['items'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return [];
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
              const Icon(Icons.price_change, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Tabela de Preços e Descontos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 340,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: 'Tabelas'),
                    Tab(text: 'Itens'),
                    Tab(text: 'Descontos'),
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
              _buildTabelasTab(),
              _buildItensTab(),
              _buildDescontosTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabelasTab() {
    return Column(
      children: [
        if (_tabelaSelecionada != null)
          Container(
            color: GridColors.primaryLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  'Tabela ativa: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(_tabelaSelecionada!['nome']?.toString() ?? ''),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => setState(() => _tabelaSelecionada = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Limpar'),
                ),
              ],
            ),
          ),
        Expanded(
          child: DynamicGridWindowsScreen<Map<String, dynamic>>(
            telaNome: 'tabela_preco',
            hasPermission: widget.hasPermission,
            fromJson: (json) => json,
            toJson: (a) => a,
            showAppBar: false,
            customActions: () => [
              CustomAction<Map<String, dynamic>>(
                icon: Icons.list_alt,
                label: 'Ver Itens',
                onPressed: (ctx, item) {
                  setState(() {
                    _tabelaSelecionada = item;
                    _tabCtrl.animateTo(1);
                    _carregarItens();
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItensTab() {
    return Column(
      children: [
        Container(
          color: GridColors.filterBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Text(
                'Tabela: ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: DropdownButton<String>(
                  value: _tabelaSelecionada?['id']?.toString(),
                  isExpanded: true,
                  hint: const Text('Selecione uma tabela'),
                  items: _tabelas.map((t) {
                    return DropdownMenuItem(
                      value: t['id']?.toString(),
                      child: Text(t['nome']?.toString() ?? ''),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    final t = _tabelas.firstWhere(
                      (x) => x['id']?.toString() == v,
                      orElse: () => <String, dynamic>{},
                    );
                    setState(() {
                      _tabelaSelecionada = t;
                    });
                    _carregarItens();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _tabelaSelecionada == null ? null : _adicionarItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Novo Item'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (_tabelaSelecionada == null)
          const Expanded(
            child: Center(
              child: Text('Selecione uma tabela para ver os itens'),
            ),
          )
        else if (_loadingItens)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Expanded(child: _buildItensGrid()),
      ],
    );
  }

  Widget _buildItensGrid() {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      key: ValueKey('itens_${_tabelaSelecionada?['id']}_$_itensGridKey'),
      telaNome: 'tabela_preco_item',
      hasPermission: widget.hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fetchEndpointOverride:
          ApiLinks.itensTabelaPreco(_tabelaSelecionada!['id'].toString()),
      createEndpointOverride:
          ApiLinks.salvarItemTabelaPreco(_tabelaSelecionada!['id'].toString()),
      updateEndpointOverride: null,
      deleteEndpointOverride: ApiLinks.deletarItemTabelaPreco(
        _tabelaSelecionada!['id'].toString(),
        ':id',
      ),
      showAppBar: false,
      fieldOverrides: const [
        FieldConfigWindows(
          fieldName: 'produto',
          label: 'Produto',
          isInForm: true,
          fieldType: FieldType.dropdown,
        ),
        FieldConfigWindows(
          fieldName: 'preco',
          label: 'Preço',
          isInForm: true,
          fieldType: FieldType.currency,
        ),
        FieldConfigWindows(
          fieldName: 'margem',
          label: 'Margem %',
          isInForm: true,
          fieldType: FieldType.percentage,
        ),
      ],
    );
  }

  Future<void> _adicionarItem() async {
    final id = _tabelaSelecionada?['id']?.toString();
    if (id == null || id.isEmpty) return;
    final res = await TabelaPrecoCaller.salvarItem(id, {
      'produtoId': null,
      'preco': 0,
      'margem': 0,
    });
    if (res.isSuccess) {
      _carregarItens();
    }
  }

  Widget _buildDescontosTab() {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'desconto',
      hasPermission: widget.hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      showAppBar: false,
    );
  }
}

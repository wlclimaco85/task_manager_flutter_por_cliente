import 'package:flutter/material.dart';

import '../utils/grid_colors.dart';

/// Coluna da grid de documentos fiscais (MDF-e / CT-e).
class DocColuna {
  final String titulo;
  final double largura;
  final String Function(Map<String, dynamic> item) valor;

  /// Fonte monoespacada/pequena para chaves e protocolos.
  final bool compacta;

  const DocColuna(this.titulo, this.valor, {this.largura = 120, this.compacta = false});
}

/// Acao da grid: vale para uma linha (menu da linha) ou para varias selecionadas ("Ações").
/// [habilitada] recebe os itens alvo e decide se a acao pode ser executada em TODOS.
class DocAcao {
  final IconData icone;
  final String rotulo;
  final bool Function(List<Map<String, dynamic>> itens) habilitada;
  final Future<void> Function(List<Map<String, dynamic>> itens) executar;

  /// Acao so faz sentido para um documento por vez (ex.: eventos, carta de correcao):
  /// nao aparece no menu "Ações" em massa.
  final bool soUm;
  final bool destrutiva;

  const DocAcao({
    required this.icone,
    required this.rotulo,
    required this.habilitada,
    required this.executar,
    this.soUm = false,
    this.destrutiva = false,
  });
}

/// Grid padrao de documentos fiscais: selecao multipla, "Ações" em massa e menu por linha.
/// No celular (largura < 720) vira lista de cartoes com os mesmos controles.
class DocumentoFiscalGrid extends StatefulWidget {
  final List<Map<String, dynamic>> itens;
  final List<DocColuna> colunas;
  final List<DocAcao> acoes;
  final Color Function(String? status) corStatus;
  final String textoVazio;

  const DocumentoFiscalGrid({
    super.key,
    required this.itens,
    required this.colunas,
    required this.acoes,
    required this.corStatus,
    required this.textoVazio,
  });

  @override
  State<DocumentoFiscalGrid> createState() => _DocumentoFiscalGridState();
}

class _DocumentoFiscalGridState extends State<DocumentoFiscalGrid> {
  final Set<Object> _selecionados = {};
  bool _executando = false;

  Object _id(Map<String, dynamic> m) => m['id'] ?? m.hashCode;

  @override
  void didUpdateWidget(covariant DocumentoFiscalGrid old) {
    super.didUpdateWidget(old);
    // apos recarregar, descarta selecao de documentos que nao existem mais
    final ids = widget.itens.map(_id).toSet();
    _selecionados.removeWhere((id) => !ids.contains(id));
  }

  List<Map<String, dynamic>> get _alvo =>
      widget.itens.where((m) => _selecionados.contains(_id(m))).toList();

  Future<void> _rodar(DocAcao a, List<Map<String, dynamic>> alvo) async {
    if (_executando) return;
    setState(() => _executando = true);
    try {
      await a.executar(alvo);
    } finally {
      if (mounted) setState(() => _executando = false);
    }
  }

  Widget _menuAcoes() {
    final alvo = _alvo;
    final disponiveis =
        widget.acoes.where((a) => !a.soUm && alvo.isNotEmpty && a.habilitada(alvo)).toList();
    return PopupMenuButton<DocAcao>(
      enabled: disponiveis.isNotEmpty && !_executando,
      tooltip: alvo.isEmpty
          ? 'Selecione documentos para executar uma ação'
          : disponiveis.isEmpty
              ? 'Nenhuma ação vale para todos os selecionados'
              : 'Ações para ${alvo.length} selecionado(s)',
      onSelected: (a) => _rodar(a, alvo),
      itemBuilder: (_) => [
        for (final a in disponiveis)
          PopupMenuItem(
            value: a,
            child: Row(children: [
              Icon(a.icone, size: 18, color: a.destrutiva ? Colors.red.shade700 : null),
              const SizedBox(width: 10),
              Text(a.rotulo),
            ]),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (_executando)
            const SizedBox(
                width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          else
            const Icon(Icons.bolt, size: 18),
          const SizedBox(width: 6),
          Text(alvo.isEmpty ? 'Ações' : 'Ações (${alvo.length})'),
          const Icon(Icons.arrow_drop_down),
        ]),
      ),
    );
  }

  Widget _menuLinha(Map<String, dynamic> m) {
    final doItem = widget.acoes.where((a) => a.habilitada([m])).toList();
    return PopupMenuButton<DocAcao>(
      enabled: doItem.isNotEmpty && !_executando,
      tooltip: 'Ações do documento',
      icon: const Icon(Icons.more_vert),
      onSelected: (a) => _rodar(a, [m]),
      itemBuilder: (_) => [
        for (final a in doItem)
          PopupMenuItem(
            value: a,
            child: Row(children: [
              Icon(a.icone, size: 18, color: a.destrutiva ? Colors.red.shade700 : null),
              const SizedBox(width: 10),
              Text(a.rotulo),
            ]),
          ),
      ],
    );
  }

  Widget _chipStatus(String? s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: widget.corStatus(s),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(s ?? '-', style: const TextStyle(color: Colors.white, fontSize: 12)),
      );

  void _alternar(Map<String, dynamic> m, bool? v) => setState(() {
        v == true ? _selecionados.add(_id(m)) : _selecionados.remove(_id(m));
      });

  bool? get _todos => _selecionados.isEmpty
      ? false
      : (_selecionados.length == widget.itens.length ? true : null);

  void _alternarTodos(bool? v) => setState(() {
        _selecionados.clear();
        if (v == true) _selecionados.addAll(widget.itens.map(_id));
      });

  @override
  Widget build(BuildContext context) {
    if (widget.itens.isEmpty) return Center(child: Text(widget.textoVazio));
    final estreito = MediaQuery.sizeOf(context).width < 720;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Checkbox(tristate: true, value: _todos, onChanged: _alternarTodos),
          Expanded(
            child: Text(
              _selecionados.isEmpty
                  ? 'Selecionar todos'
                  : '${_selecionados.length} de ${widget.itens.length} selecionado(s)',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _menuAcoes(),
        ]),
        const Divider(height: 8),
        Expanded(child: estreito ? _cartoes() : _tabela()),
      ],
    );
  }

  Widget _cartoes() => ListView.separated(
        itemCount: widget.itens.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final m = widget.itens[i];
          final sel = _selecionados.contains(_id(m));
          return Card(
            color: sel ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .35) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Checkbox(value: sel, onChanged: (v) => _alternar(m, v)),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                          '${widget.colunas[0].titulo} ${widget.colunas[0].valor(m)} • ${widget.colunas[1].titulo} ${widget.colunas[1].valor(m)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      _chipStatus(m['status']?.toString()),
                    ]),
                    for (final c in widget.colunas.skip(2))
                      if (c.valor(m).isNotEmpty && c.valor(m) != '-')
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text('${c.titulo}: ${c.valor(m)}',
                              style: const TextStyle(fontSize: 12)),
                        ),
                  ]),
                ),
                _menuLinha(m),
              ]),
            ),
          );
        },
      );

  Widget _tabela() {
    final larguraTotal =
        widget.colunas.fold<double>(0, (a, c) => a + c.largura) + 48 + 110 + 56;
    return LayoutBuilder(builder: (context, box) {
      final largura = larguraTotal < box.maxWidth ? box.maxWidth : larguraTotal;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: largura,
          child: Column(children: [
            _cabecalho(),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                itemCount: widget.itens.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => _linha(widget.itens[i]),
              ),
            ),
          ]),
        ),
      );
    });
  }

  Widget _cabecalho() => Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
        height: 40,
        child: Row(children: [
          const SizedBox(width: 48),
          for (final c in widget.colunas)
            SizedBox(
              width: c.largura,
              child: Text(c.titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 110, child: Text('Situação', style: TextStyle(fontWeight: FontWeight.w700))),
          const SizedBox(width: 56),
        ]),
      );

  Widget _linha(Map<String, dynamic> m) {
    final sel = _selecionados.contains(_id(m));
    return Container(
      color: sel ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .35) : null,
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(children: [
        SizedBox(
            width: 48,
            child: Checkbox(value: sel, onChanged: (v) => _alternar(m, v))),
        for (final c in widget.colunas)
          SizedBox(
            width: c.largura,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                c.valor(m),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: c.compacta ? 11 : 13),
              ),
            ),
          ),
        SizedBox(width: 110, child: Align(alignment: Alignment.centerLeft, child: _chipStatus(m['status']?.toString()))),
        SizedBox(width: 56, child: _menuLinha(m)),
      ]),
    );
  }
}


/// Listagem de documentos fiscais: painel de filtros (como o da NFS-e) + [DocumentoFiscalGrid].
/// Filtra no cliente os itens ja carregados: busca (nº, chave, protocolo), situacao, ambiente e,
/// quando [tipos] vem preenchido (CT-e), o tipo do documento. Abaixo de 720px o painel vira um
/// bloco recolhivel acima da grid.
class DocumentoFiscalListagem extends StatefulWidget {
  final List<Map<String, dynamic>> itens;
  final List<DocColuna> colunas;
  final List<DocAcao> acoes;
  final Color Function(String? status) corStatus;
  final String textoVazio;
  final List<String> statusOpcoes;

  /// Filtro por tipo (campo `tipoCte`): codigo -> rotulo. Nulo = sem filtro de tipo.
  final Map<int, String>? tipos;

  const DocumentoFiscalListagem({
    super.key,
    required this.itens,
    required this.colunas,
    required this.acoes,
    required this.corStatus,
    required this.textoVazio,
    required this.statusOpcoes,
    this.tipos,
  });

  @override
  State<DocumentoFiscalListagem> createState() => _DocumentoFiscalListagemState();
}

class _DocumentoFiscalListagemState extends State<DocumentoFiscalListagem> {
  final _busca = TextEditingController();
  String? _status;
  int? _tpAmb;
  int? _tipo;
  bool _painelAberto = true;

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  bool get _ativo =>
      _busca.text.trim().isNotEmpty || _status != null || _tpAmb != null || _tipo != null;

  bool _aceita(Map<String, dynamic> m) {
    final termo = _busca.text.trim().toLowerCase();
    if (termo.isNotEmpty) {
      final alvo = '${m['numero'] ?? ''} ${m['chaveAcesso'] ?? ''} ${m['protocolo'] ?? ''}'.toLowerCase();
      if (!alvo.contains(termo)) return false;
    }
    if (_status != null && m['status']?.toString() != _status) return false;
    if (_tpAmb != null && m['tpAmb'] != _tpAmb) return false;
    if (_tipo != null && (m['tipoCte'] ?? 0) != _tipo) return false;
    return true;
  }

  void _limpar() => setState(() {
        _busca.clear();
        _status = null;
        _tpAmb = null;
        _tipo = null;
      });

  InputDecoration _dec(String rotulo, {IconData? icone}) => InputDecoration(
        labelText: rotulo,
        isDense: true,
        filled: true,
        fillColor: GridColors.card,
        prefixIcon: icone == null ? null : Icon(icone, size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GridColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: GridColors.borderSubtle),
        ),
      );

  List<Widget> _campos(int total, int exibidos) => [
        TextField(
          controller: _busca,
          decoration: _dec('Buscar nº, chave ou protocolo', icone: Icons.search),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          value: _status,
          isExpanded: true,
          decoration: _dec('Situação'),
          items: [
            const DropdownMenuItem<String?>(value: null, child: Text('Todas')),
            for (final s in widget.statusOpcoes) DropdownMenuItem<String?>(value: s, child: Text(s)),
          ],
          onChanged: (v) => setState(() => _status = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          value: _tpAmb,
          isExpanded: true,
          decoration: _dec('Ambiente'),
          items: const [
            DropdownMenuItem<int?>(value: null, child: Text('Todos')),
            DropdownMenuItem<int?>(value: 2, child: Text('Homologação')),
            DropdownMenuItem<int?>(value: 1, child: Text('Produção')),
          ],
          onChanged: (v) => setState(() => _tpAmb = v),
        ),
        if (widget.tipos != null) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int?>(
            value: _tipo,
            isExpanded: true,
            decoration: _dec('Tipo'),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              for (final e in widget.tipos!.entries)
                DropdownMenuItem<int?>(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _tipo = v),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          _ativo ? '$exibidos de $total documento(s)' : '$total documento(s)',
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _ativo ? _limpar : null,
            icon: const Icon(Icons.filter_alt_off, size: 18),
            label: const Text('Limpar filtros'),
          ),
        ),
      ];

  Widget _painel(int total, int exibidos) => Container(
        width: 240,
        decoration: const BoxDecoration(
          color: GridColors.filterBackground,
          border: Border(right: BorderSide(color: GridColors.divider)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.tune, size: 16, color: GridColors.primary),
              const SizedBox(width: 6),
              const Text('Filtros', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 18),
                tooltip: 'Ocultar filtros',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _painelAberto = false),
              ),
            ]),
            const SizedBox(height: 12),
            ..._campos(total, exibidos),
          ]),
        ),
      );

  Widget _faixaFechada() => Container(
        width: 40,
        decoration: const BoxDecoration(
          color: GridColors.filterBackground,
          border: Border(right: BorderSide(color: GridColors.divider)),
        ),
        child: Column(children: [
          const SizedBox(height: 8),
          IconButton(
            icon: Icon(Icons.tune, color: _ativo ? GridColors.primary : null),
            tooltip: _ativo ? 'Mostrar filtros (há filtros ativos)' : 'Mostrar filtros',
            onPressed: () => setState(() => _painelAberto = true),
          ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final filtrados = widget.itens.where(_aceita).toList();
    final grid = DocumentoFiscalGrid(
      itens: filtrados,
      colunas: widget.colunas,
      acoes: widget.acoes,
      corStatus: widget.corStatus,
      textoVazio: widget.itens.isEmpty ? widget.textoVazio : 'Nenhum documento encontrado com os filtros.',
    );
    final total = widget.itens.length;
    final largo = MediaQuery.sizeOf(context).width >= 720;
    if (largo) {
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (_painelAberto) _painel(total, filtrados.length) else _faixaFechada(),
        Expanded(child: Padding(padding: const EdgeInsets.only(left: 12), child: grid)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        decoration: BoxDecoration(
          color: GridColors.filterBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GridColors.divider),
        ),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(Icons.tune, size: 18, color: GridColors.primary),
          title: Text(_ativo ? 'Filtros (ativos)' : 'Filtros'),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          children: _campos(total, filtrados.length),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(child: grid),
    ]);
  }
}

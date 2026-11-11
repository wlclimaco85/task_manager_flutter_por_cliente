import 'package:flutter/material.dart';

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

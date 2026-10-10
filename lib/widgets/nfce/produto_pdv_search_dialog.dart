import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/nfce_service.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Modal dialog de busca de produtos para PDV (Web, Mobile e Windows).
/// Traz produtos em ordem alfabetica com campo de busca no topo e rolagem infinita.
class ProdutoPdvSearchDialog extends StatefulWidget {
  final int empresaId;

  const ProdutoPdvSearchDialog({
    super.key,
    required this.empresaId,
  });

  static Future<Map<String, dynamic>?> show(BuildContext context) {
    final empId = TenantContext.empresaId ?? 0;
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ProdutoPdvSearchDialog(empresaId: empId),
    );
  }

  @override
  State<ProdutoPdvSearchDialog> createState() => _ProdutoPdvSearchDialogState();
}

class _ProdutoPdvSearchDialogState extends State<ProdutoPdvSearchDialog> {
  final NfceService _service = NfceService();
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  List<Map<String, dynamic>> _produtos = [];
  Timer? _debounce;
  bool _loading = false;
  bool _loadingMore = false;
  int _searchToken = 0;
  int _page = 0;
  int _totalElements = 0;
  bool _isLast = false;
  String _termoAtual = '';

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _carregarPrimeiraPagina();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || _loadingMore || _isLast) return;
    if (!_scrollCtrl.hasClients) return;
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 80) {
      _carregarProximaPagina();
    }
  }

  void _ordenarAlfabetico(List<Map<String, dynamic>> list) {
    list.sort((a, b) {
      final nomeA = (a['nome'] ?? '').toString().toLowerCase();
      final nomeB = (b['nome'] ?? '').toString().toLowerCase();
      return nomeA.compareTo(nomeB);
    });
  }

  Future<void> _carregarPrimeiraPagina() async {
    final token = ++_searchToken;
    setState(() {
      _loading = true;
    });

    try {
      final res = await _service.buscarProdutosPaginado(
        query: _termoAtual,
        empresaId: widget.empresaId,
        page: 0,
        tamanho: 20,
      );
      if (!mounted || token != _searchToken) return;

      final itens = res.itens.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      _ordenarAlfabetico(itens);

      setState(() {
        _produtos = itens;
        _totalElements = res.totalElements;
        _isLast = res.isLast;
        _page = 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _produtos = [];
        _totalElements = 0;
        _isLast = true;
        _loading = false;
      });
    }
  }

  Future<void> _carregarProximaPagina() async {
    final token = ++_searchToken;
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;

    try {
      final res = await _service.buscarProdutosPaginado(
        query: _termoAtual,
        empresaId: widget.empresaId,
        page: nextPage,
        tamanho: 20,
      );
      if (!mounted || token != _searchToken) return;

      final novosItens = res.itens.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      final listaAtualizada = List<Map<String, dynamic>>.from(_produtos)..addAll(novosItens);
      _ordenarAlfabetico(listaAtualizada);

      setState(() {
        _produtos = listaAtualizada;
        _totalElements = res.totalElements;
        _isLast = res.isLast;
        _page = nextPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() => _loadingMore = false);
    }
  }

  void _onSearchChanged(String val) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _termoAtual = val.trim();
      _carregarPrimeiraPagina();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = GridColors.primary;

    final contadorTexto = _loading
        ? 'Buscando produtos...'
        : '${_produtos.length} de $_totalElements produto(s)';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Buscar Produto',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // ── Input de Busca ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Digite o nome ou código do produto...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),

            // ── Contador de Resultados ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    contadorTexto,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),

            // ── Lista de Produtos (Rolagem infinita) ─────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _produtos.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Nenhum produto encontrado.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: _scrollCtrl,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemCount: _produtos.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _produtos.length) {
                              return const Padding(
                                padding: EdgeInsets.all(12),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }

                            final p = _produtos[i];
                            final preco = (p['preco'] ?? p['precoVenda'] ?? 0).toDouble();
                            final nome = p['nome']?.toString() ?? '—';
                            final codigo = p['codigo']?.toString() ?? '';
                            final un = (p['unidadeComercial'] ?? p['unidade'])?.toString();

                            return ListTile(
                              leading: const Icon(Icons.inventory_2_outlined, color: Colors.blueGrey),
                              title: Text(
                                nome,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (codigo.isNotEmpty) 'Cód: $codigo',
                                  if (un != null && un.isNotEmpty) 'Un: $un',
                                  'R\$ ${preco.toStringAsFixed(2)}',
                                ].join(' • '),
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.add_circle, color: GridColors.secondary),
                                tooltip: 'Adicionar produto',
                                onPressed: () => Navigator.of(context).pop(p),
                              ),
                              onTap: () => Navigator.of(context).pop(p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

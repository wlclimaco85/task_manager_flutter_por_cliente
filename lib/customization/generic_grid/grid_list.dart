// lib/data/customization/generic_grid/grid_list.dart
// -----------------------------------------------------------------------------
// 🗂️ Renderização de cards, filtros e seleção múltipla do grid
// Mantém comportamento do monolito original: cards, seleção, badges de status,
// ações por item (editar/excluir/servidor) e suporte a tela de detalhes.
// -----------------------------------------------------------------------------
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/app_logger.dart'; // L.d/L.i/L.w/L.e
import '../../../widgets/user_banners.dart';

import 'grid_helpers.dart';
import 'grid_form.dart';
import 'grid_models.dart';
import 'grid_theme.dart';
import '../../utils/grid_texts.dart';

class GridListScreen extends StatefulWidget {
  final String title;
  final String fetchEndpoint;
  final String createEndpoint;
  final String updateEndpoint; // ':id'
  final String deleteEndpoint; // ':id'
  final bool Function(String permission) hasPermission;
  final Future<bool> Function(String permission)? asyncHasPermission;
  final List<FieldConfig> fieldConfigs;

  final String idFieldName;
  final PaginationConfig paginationConfig;

  final void Function(Map<String, dynamic> item, BuildContext context)?
      onItemTap;
  final List<CustomAction> Function()? customActions;

  final bool enableSearch;
  final Map<String, dynamic>? initialFilters;
  final String storageKey;
  final Widget Function(Map<String, dynamic> item)? detailScreenBuilder;
  final Map<String, dynamic>? extraParams;
  final bool enableDebugMode;
  final bool useUserBannerAppBar;
  final VoidCallback? onUserBannerTapped;
  final VoidCallback? onBannerRefresh;

  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic> formData)?
      transformFormData;

  final String? baseUrlForMultipart;
  final Future<Map<String, String>> Function()? authHeadersProvider;

  final List<ServerAction>? serverActions;
  final bool showAppBar;
  final bool showFab;

  /// Chamado uma vez após a inicialização, entregando ao pai uma referência
  /// para abrir o diálogo "Campos visíveis" desta tela — usado quando o
  /// AppBar (ex.: UserBannerAppBar) é renderizado por um widget pai que não
  /// tem acesso direto ao estado de visibilidade de campos, que vive aqui.
  final ValueChanged<VoidCallback>? onFieldSettingsReady;
  final ValueChanged<VoidCallback>? onFilterToggleReady;

  /// Notifica o pai sempre que o estado de customização (filtros preenchidos
  /// e/ou campos ocultos em relação ao padrão) mudar — usado para mostrar um
  /// indicador visual nos ícones de filtro/colunas do AppBar.
  final void Function(
      {required bool hasActiveFilters,
      required bool hasCustomColumns})? onCustomizationStateChanged;

  const GridListScreen({
    super.key,
    required this.title,
    required this.fetchEndpoint,
    required this.createEndpoint,
    required this.updateEndpoint,
    required this.deleteEndpoint,
    required this.hasPermission,
    this.asyncHasPermission,
    required this.fieldConfigs,
    this.idFieldName = 'id',
    this.paginationConfig = const PaginationConfig(),
    this.onItemTap,
    this.customActions,
    this.enableSearch = true,
    this.initialFilters,
    this.storageKey = 'generic_mobile_grid_settings',
    this.detailScreenBuilder,
    this.extraParams,
    this.enableDebugMode = false,
    this.useUserBannerAppBar = false,
    this.onUserBannerTapped,
    this.onBannerRefresh,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    this.transformFormData,
    this.baseUrlForMultipart,
    this.authHeadersProvider,
    this.serverActions = const [],
    this.showAppBar = true,
    this.showFab = true,
    this.onFieldSettingsReady,
    this.onFilterToggleReady,
    this.onCustomizationStateChanged,
  });

  @override
  State<GridListScreen> createState() => _GridListScreenState();
}

class _GridListScreenState extends State<GridListScreen> {
  final ScrollController _scroll = ScrollController();
  final Map<String, TextEditingController> _filterCtrls = {};
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, bool> _fieldVisibility = {};
  bool _filtersOpen = false;
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;
  int _total = 0;
  final int _pageSize = 20;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filtered = [];
  late List<CustomAction> _customActions;
  bool _selectionMode = false;
  final Map<String, bool> _sel = {};
  int? _lastStatusCode;
  String? _loadError;

  // permissões (assíncronas)
  final Map<String, bool> _permCache = {};
  bool _permReady = true;

  @override
  void initState() {
    super.initState();
    L.i('[GridList] init for "${widget.title}"');
    widget.onFieldSettingsReady?.call(_showFieldSettings);
    widget.onFilterToggleReady?.call(_toggleFilters);
    _init();
  }

  void _toggleFilters() => setState(() => _filtersOpen = !_filtersOpen);

  Future<void> _init() async {
    // visibilidade default dos campos + filtros
    for (final c in widget.fieldConfigs) {
      _fieldVisibility[c.fieldName] = c.isVisibleByDefault;
      if (c.isFilterable) _filterCtrls[c.fieldName] = TextEditingController();
    }

    // restaura preferências salvas (campos visíveis e filtros digitados)
    await _loadFieldPreferences();
    await _loadFilterPreferences();

    // filtros iniciais explícitos do chamador têm prioridade sobre o salvo
    widget.initialFilters?.forEach((k, v) {
      if (_filterCtrls.containsKey(k)) {
        _filterCtrls[k]!.text = v?.toString() ?? '';
      }
    });
    _notifyCustomizationState();

    _customActions =
        widget.customActions != null ? widget.customActions!() : [];

    // permissões async
    await _resolveAsyncPerms();

    // eventos de scroll (infinite load)
    _scroll.addListener(_onScroll);

    // primeira carga
    await _load(reset: true);
  }

  String get _prefsKeyBase => '${widget.storageKey}_${widget.title}';

  Future<void> _loadFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final c in widget.fieldConfigs) {
        // Sincroniza com grid_page.dart: chave sem "_field_" no meio (card #425)
        final saved = prefs.getBool('$_prefsKeyBase${c.fieldName}');
        if (saved != null) _fieldVisibility[c.fieldName] = saved;
      }
    } catch (e) {
      L.w('[GridList] load field prefs fail: $e');
    }
  }

  Future<void> _saveFieldPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final c in widget.fieldConfigs) {
        // Sincroniza com grid_page.dart: chave sem "_field_" no meio (card #425)
        await prefs.setBool(
          '$_prefsKeyBase${c.fieldName}',
          _fieldVisibility[c.fieldName] ?? c.isVisibleByDefault,
        );
      }
    } catch (e) {
      L.w('[GridList] save field prefs fail: $e');
    }
  }

  Future<void> _loadFilterPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _filterCtrls.entries) {
        final saved = prefs.getString('${_prefsKeyBase}_filter_${entry.key}');
        if (saved != null && saved.isNotEmpty) entry.value.text = saved;
      }
    } catch (e) {
      L.w('[GridList] load filter prefs fail: $e');
    }
  }

  Future<void> _saveFilterPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final entry in _filterCtrls.entries) {
        final key = '${_prefsKeyBase}_filter_${entry.key}';
        if (entry.value.text.isEmpty) {
          await prefs.remove(key);
        } else {
          await prefs.setString(key, entry.value.text);
        }
      }
    } catch (e) {
      L.w('[GridList] save filter prefs fail: $e');
    }
  }

  /// Recalcula se há filtros preenchidos e/ou campos ocultos em relação ao
  /// padrão, e avisa o pai (usado para o indicador visual nos ícones do AppBar).
  void _notifyCustomizationState() {
    final hasActiveFilters =
        _filterCtrls.values.any((c) => c.text.trim().isNotEmpty);
    final hasCustomColumns = widget.fieldConfigs.any((c) =>
        (_fieldVisibility[c.fieldName] ?? c.isVisibleByDefault) !=
        c.isVisibleByDefault);
    widget.onCustomizationStateChanged?.call(
      hasActiveFilters: hasActiveFilters,
      hasCustomColumns: hasCustomColumns,
    );
  }

  Future<void> _resolveAsyncPerms() async {
    final f = widget.asyncHasPermission;
    if (f == null) {
      _permCache
          .addAll({'create': true, 'edit': true, 'delete': true, 'view': true});
      for (final a in widget.serverActions ?? []) {
        if ((a.requiredPermission ?? '').isNotEmpty) {
          _permCache[a.requiredPermission!] = true;
        }
      }
      _permReady = true;
      return;
    }

    final needs = <String>{'create', 'edit', 'delete', 'view'};
    final extra = widget.serverActions
            ?.map((a) => a.requiredPermission)
            .whereType<String>() ??
        const Iterable<String>.empty();
    needs.addAll(extra);

    for (final p in needs) {
      try {
        final ok = await f(p);
        // Se async retornou false, respeita o hasPermission sincrono como
        // fallback — evita bloquear acoes quando as permissoes ainda nao
        // foram salvas no SharedPreferences.
        _permCache[p] = (ok == true) || widget.hasPermission(p);
        L.d('[GridList] perm:$p => ${_permCache[p]}');
      } catch (e, st) {
        L.w('[GridList] perm:$p fallback true. $e\n$st');
        _permCache[p] = true;
      }
    }
    _permReady = true;
  }

  bool _can(String perm) {
    // fallback sempre true para não bloquear (mantém do original)
    return _permCache[perm] ?? true;
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in _filterCtrls.values) {
      c.dispose();
    }
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 50) {
      if (_hasMore && !_loading) _load(reset: false);
    }
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) {
      setState(() {
        _page = 0;
        _hasMore = true;
        _loading = true;
      });
    } else {
      setState(() => _loading = true);
    }

    final url = _buildUrl(reset ? 0 : _page);
    L.i('[GridList] GET $url');

    try {
      final resp = await NetworkCaller().getRequest(url);
      if (resp.statusCode == 200 && resp.body != null) {
        // NetworkResponse._toMap já normaliza List do backend em {'data': [...]},
        // então body é sempre Map e a lista sai de data/dados.
        final body = resp.body ?? <String, dynamic>{};
        final list = extractAnyList(body['data'] ?? body['dados'] ?? body);
        final total = ((body['totalElements'] ??
                body['total'] ??
                (body['data'] is Map ? body['data']['totalElements'] : null) ??
                (body['dados'] is Map
                    ? body['dados']['totalElements']
                    : null))) as int? ??
            list.length;

        setState(() {
          if (reset) {
            _items = list;
          } else {
            _items.addAll(list);
          }
          _filtered = List.from(_items);
          _total = total;
          _hasMore = _items.length < _total;
          _page++;
          _loading = false;
          _lastStatusCode = null;
          _loadError = null;
        });
        L.s('[GridList] loaded: ${list.length} (total=$_total page=$_page)');
      } else {
        L.w('[GridList] load failed: status ${resp.statusCode}');
        _snack('Erro ao carregar: ${resp.statusCode}', true);
        setState(() {
          _loading = false;
          _lastStatusCode = resp.statusCode;
          _loadError = _messageForStatus(resp.statusCode);
        });
      }
    } catch (e, st) {
      L.e('[GridList] load exception: $e\n$st');
      _snack('Erro ao carregar: $e', true);
      if (mounted) {
        setState(() {
          _loading = false;
          _lastStatusCode = -1;
          _loadError = 'Nao foi possivel carregar os dados.';
        });
      }
    }
  }

  String _messageForStatus(int statusCode) {
    if (statusCode == 403) {
      return 'Seu usuario nao tem permissao para consultar esta tela.';
    }
    if (statusCode == 401) {
      return 'Sessao expirada ou usuario nao autenticado.';
    }
    if (statusCode == 404) {
      return 'Endpoint nao encontrado no backend.';
    }
    return 'Nao foi possivel carregar os dados desta tela.';
  }

  String _buildUrl(int page) {
    String url = '${widget.fetchEndpoint}?page=$page&size=$_pageSize';

    if (_searchCtrl.text.isNotEmpty) {
      url += '&search=${Uri.encodeComponent(_searchCtrl.text)}';
    }

    for (final c in widget.fieldConfigs.where((x) => x.isFilterable)) {
      final v = _filterCtrls[c.fieldName]?.text;
      if (v != null && v.isNotEmpty) {
        url += '&${c.fieldName}=${Uri.encodeComponent(v)}';
      }
    }

    widget.extraParams?.forEach((k, v) {
      url += '&$k=${Uri.encodeComponent(v.toString())}';
    });

    return url;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: widget.showAppBar
          ? (widget.useUserBannerAppBar
              // UserBannerAppBar ja e PreferredSizeWidget e calcula a propria
              // altura (banner + subheader verde). NAO embrulhar em PreferredSize
              // com altura fixa, senao o subheader (FilterActionBar) e cortado.
              ? UserBannerAppBar(
                  screenTitle: widget.title,
                  onTapped: widget.onUserBannerTapped,
                  onUserTap: widget.onUserBannerTapped,
                  onRefresh: widget.onBannerRefresh ?? () => _load(reset: true),
                  isLoading: _loading,
                  onFilterToggle: () =>
                      setState(() => _filtersOpen = !_filtersOpen),
                  onColumns: _showFieldSettings,
                  showFilterButton: widget.useUserBannerAppBar,
                )
              : (_selectionMode ? _selectionAppBar() : _normalAppBar()))
          : null,
      floatingActionButton: widget.showFab ? _buildFab() : null,
      body: Column(
        children: [
          if (_filtersOpen) _buildFilters(context),
          if ((widget.serverActions?.any((a) => !a.endpoint.contains(':id')) ??
              false))
            _buildServerActionsBar(context),
          Expanded(
            child: Stack(
              children: [
                RefreshIndicator.adaptive(
                  onRefresh: () => _load(reset: true),
                  child: _buildListContent(context),
                ),
                if (_loading && _filtered.isEmpty)
                  Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _normalAppBar() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppBar(
      title: Text(widget.title,
          style: tt.titleLarge
              ?.copyWith(fontWeight: FontWeight.w600, color: cs.onPrimary)),
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation: 3,
      actions: [
        IconButton(
          onPressed: _loading ? null : () => _load(reset: true),
          icon: _loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(cs.onPrimary)),
                )
              : const Icon(Icons.refresh),
        ),
        IconButton(
          onPressed: _showFieldSettings,
          icon: const Icon(Icons.view_column),
          tooltip: 'Configurar campos',
        ),
        IconButton(
          onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
          icon: const Icon(Icons.filter_list),
          tooltip: 'Filtros',
        ),
      ],
    );
  }

  AppBar _selectionAppBar() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppBar(
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _toggleSelectionMode,
      ),
      title: Text('${_sel.length} selecionado(s)',
          style: tt.bodyMedium?.copyWith(color: cs.onPrimary)),
      actions: [
        IconButton(
          icon: Icon(_sel.length == _filtered.length
              ? Icons.deselect
              : Icons.select_all),
          onPressed:
              _sel.length == _filtered.length ? _deselectAll : _selectAll,
        ),
        if (_can('delete') && _sel.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteSelected,
          ),
      ],
    );
  }

  Widget? _buildFab() {
    final canCreate = _can('create');
    if (!canCreate) return null;

    return FloatingActionButton(
      onPressed: () async {
        final ok = await _confirm(
          title: 'Novo registro',
          message: 'Deseja abrir o formulário para adicionar um novo item?',
          confirmText: 'Abrir',
        );
        if (ok == true) {
          L.d('[GridList] abrir form de criação');
          _openForm();
        }
      },
      backgroundColor: GridColors.primary,
      foregroundColor: GridColors.textPrimary,
      tooltip: 'Adicionar',
      child: const Icon(Icons.add),
    );
  }

  Widget _buildListContent(BuildContext context) {
    if (!_loading && _filtered.isEmpty && _loadError != null) {
      return ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 120),
        children: [_buildErrorState(context)],
      );
    }

    if (!_loading && _filtered.isEmpty) {
      return ListView(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 120),
        children: [_buildEmptyState(context)],
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 96),
      itemCount: _filtered.length + (_loading ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == _filtered.length) return _loadingIndicator(ctx);
        return _card(ctx, _filtered[i], i);
      },
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final status = _lastStatusCode;
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GridColors.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: GridColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                color: GridColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              status == 403 ? 'Acesso negado' : 'Erro ao carregar',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GridColors.textSecondary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Nao foi possivel carregar os dados.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GridColors.textMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${status ?? '-'}',
              style: const TextStyle(
                color: GridColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : () => _load(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      elevation: 0,
      color: GridColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GridColors.divider.withValues(alpha: 0.8)),
      ),
      child: const Padding(
        padding: EdgeInsets.fromLTRB(18, 26, 18, 24),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, color: GridColors.textMuted, size: 42),
            SizedBox(height: 12),
            Text(
              'Nenhum registro encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GridColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Puxe para atualizar ou ajuste os filtros da tela.',
              textAlign: TextAlign.center,
              style: TextStyle(color: GridColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Filtros
  // ---------------------------------------------------------------------------
  Widget _buildFilters(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.filter_alt, color: cs.primary),
            const SizedBox(width: 8),
            Text('Filtros e Busca', style: tt.titleMedium),
            const Spacer(),
            IconButton(
              onPressed: () => setState(() => _filtersOpen = false),
              icon:
                  Icon(Icons.close, color: cs.onSurface.withValues(alpha: 0.6)),
            ),
          ]),
          const SizedBox(height: 12),
          if (widget.enableSearch) ...[
            Text('Busca Global', style: tt.bodyMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar...',
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applyFilters();
                          L.d('[GridList] filtro global limpo');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none),
              ),
              onChanged: (_) {
                L.d('[GridList] filtro global="${_searchCtrl.text}"');
                _applyFilters();
              },
            ),
            const SizedBox(height: 16),
          ],
          Text('Filtros por Campo', style: tt.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: widget.fieldConfigs
                .where((c) => c.isFilterable)
                .map((c) => SizedBox(
                      width: 240,
                      child: TextField(
                        controller: _filterCtrls[c.fieldName],
                        decoration: InputDecoration(
                          labelText: c.label,
                          prefixIcon:
                              Icon(c.icon ?? Icons.filter_list_alt, size: 18),
                          suffixIcon:
                              _filterCtrls[c.fieldName]?.text.isNotEmpty == true
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _filterCtrls[c.fieldName]?.clear();
                                        _applyFilters();
                                        L.d('[GridList] filtro "${c.fieldName}" limpo');
                                      },
                                    )
                                  : null,
                          filled: true,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none),
                        ),
                        onChanged: (_) {
                          L.d('[GridList] filtro "${c.fieldName}"="${_filterCtrls[c.fieldName]?.text}"');
                          _applyFilters();
                        },
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            FilledButton.tonal(
              onPressed: _clearFilters,
              child: const Row(children: [
                Icon(Icons.clear_all, size: 18),
                SizedBox(width: 6),
                Text('Limpar')
              ]),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _applyFilters,
              child: const Row(children: [
                Icon(Icons.check, size: 18),
                SizedBox(width: 6),
                Text('Aplicar')
              ]),
            ),
          ]),
        ]),
      ),
    );
  }

  void _applyFilters() async {
    await _saveFilterPreferences();
    _notifyCustomizationState();
    // aqui mantemos a semântica anterior (recarregar do backend)
    await _load(reset: true);
  }

  void _clearFilters() {
    for (final c in _filterCtrls.values) {
      c.clear();
    }
    _searchCtrl.clear();
    L.d('[GridList] todos os filtros limpos');
    _applyFilters();
  }

  // ---------------------------------------------------------------------------
  // Cards / Lista
  // ---------------------------------------------------------------------------
  Widget _loadingIndicator(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: _hasMore
            ? Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(cs.primary)),
                const SizedBox(height: 12),
                const Text('Carregando mais...')
              ])
            : Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle,
                    color: cs.primary.withValues(alpha: 0.6), size: 40),
                const SizedBox(height: 8),
                const Text('Todos os itens foram carregados')
              ]),
      ),
    );
  }

  Widget _card(BuildContext context, Map<String, dynamic> item, int index) {
    final id = getNestedValue(item, widget.idFieldName)?.toString() ?? '';
    final isSelected = _sel[id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
              color: isSelected
                  ? GridColors.primary
                  : GridColors.primary.withValues(alpha: 0.3)),
        ),
        color: isSelected
            ? GridColors.primary.withValues(alpha: 0.06)
            : GridColors.card,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _selectionMode
              ? () => _toggleSel(id, !isSelected)
              : () => widget.onItemTap?.call(item, context),
          onLongPress: () {
            if (!_selectionMode) {
              _toggleSelectionMode();
              _toggleSel(id, true);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                if (_selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (v) => _toggleSel(id, v ?? false),
                    ),
                  ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GridColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('#$id',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: GridColors.primary)),
                ),
                const Spacer(),
                if (_hasStatusField(item)) _statusBadge(item),
              ]),
              const SizedBox(height: 8),
              ..._visibleFields(item),
              const SizedBox(height: 8),
              _cardActions(item),
            ]),
          ),
        ),
      ),
    );
  }

  bool _hasStatusField(Map<String, dynamic> item) {
    return item.containsKey('status') ||
        item.containsKey('ativo') ||
        item.containsKey('situacao');
  }

  Widget _statusBadge(Map<String, dynamic> item) {
    final raw = (getNestedValue(item, 'status') ??
            getNestedValue(item, 'ativo') ??
            getNestedValue(item, 'situacao'))
        ?.toString()
        .toLowerCase();
    Color color;
    String text;
    switch (raw) {
      case 'ativo':
      case 'true':
      case '1':
      case 'aberto':
        color = GridColors.success;
        text = 'Ativo';
        break;
      case 'inativo':
      case 'false':
      case '0':
      case 'fechado':
        color = GridColors.error;
        text = 'Inativo';
        break;
      case 'pendente':
        color = GridColors.warning;
        text = 'Pendente';
        break;
      default:
        color = GridColors.primary;
        text = raw?.toUpperCase() ?? 'Status';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style:
            TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  /// Formata datas ISO 8601 para dd/MM/yyyy nos cards.
  String _formatarValorCampo(String valor) {
    if (valor.length > 10 && valor.contains('T')) {
      final parsed = DateTime.tryParse(valor);
      if (parsed != null) {
        final dia = parsed.day.toString().padLeft(2, '0');
        final mes = parsed.month.toString().padLeft(2, '0');
        final ano = parsed.year.toString();
        return '$dia/$mes/$ano';
      }
    }
    return valor;
  }

  List<Widget> _visibleFields(Map<String, dynamic> item) {
    final visible = widget.fieldConfigs
        .where((c) =>
            _fieldVisibility[c.fieldName] == true &&
            c.fieldName != widget.idFieldName &&
            c.showInCard)
        .toList();
    final rows = <Widget>[];
    for (int i = 0; i < visible.length; i += 2) {
      final children = <Widget>[];
      children.add(_fieldInline(visible[i], item));
      if (i + 1 < visible.length) {
        children.add(const SizedBox(width: 16));
        children.add(_fieldInline(visible[i + 1], item));
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(children: children),
      ));
    }
    return rows;
  }

  Widget _fieldInline(FieldConfig c, Map<String, dynamic> item) {
    if (c.fieldType == FieldType.file) {
      final display =
          getNestedValue(item, c.displayFieldName ?? c.fieldName)?.toString() ??
              '';
      if (display.isEmpty) return const SizedBox.shrink();
      return Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.label,
              style: TextStyle(
                  fontSize: 11, color: Colors.black.withValues(alpha: 0.6))),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.attach_file, size: 14, color: GridColors.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                display,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  decoration: TextDecoration.underline,
                  color: GridColors.primary,
                ),
              ),
            ),
          ]),
        ]),
      );
    }

    final rawVal = getNestedValue(item, c.displayFieldName ?? c.fieldName);
    String raw = '';
    if (rawVal is List) {
      raw = rawVal.map((e) {
        if (e is Map) {
          return (e['description'] ??
                      e['nome'] ??
                      e['name'] ??
                      e['label'] ??
                      e['key'] ??
                      e['id'])
                  ?.toString() ??
              '';
        }
        return e.toString();
      }).where((s) => s.isNotEmpty).join(', ');
    } else {
      raw = rawVal?.toString() ?? '';
    }
    if (raw.isEmpty) return const SizedBox.shrink();
    final value = _formatarValorCampo(raw);
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(c.label,
            style: TextStyle(
                fontSize: 11, color: Colors.black.withValues(alpha: 0.6))),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // Ações do Card
  // ---------------------------------------------------------------------------
  Widget _cardActions(Map<String, dynamic> item) {
    final perItemServer = (widget.serverActions ?? const <ServerAction>[])
        .where((a) => (a.endpoint).contains(':id'))
        .where((a) {
      final perm = a.requiredPermission;
      final effectivePerm = (perm == null || perm.isEmpty) ? 'view' : perm;
      return _can(effectivePerm) && widget.hasPermission(effectivePerm);
    }).toList();

    Widget iconBtn({
      required IconData icon,
      required Color color,
      required VoidCallback onPressed,
      String? tooltip,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Tooltip(
          message: tooltip ?? '',
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: GridColors.divider),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      );
    }

    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      if (widget.enableDebugMode)
        iconBtn(
          icon: Icons.bug_report,
          color: Colors.black.withValues(alpha: 0.6),
          tooltip: 'Ver JSON',
          onPressed: () => _showAllFieldsDebug(context, item),
        ),
      if (_can('view') && widget.hasPermission('view'))
        iconBtn(
          icon: Icons.visibility_outlined,
          color: GridColors.secondary,
          tooltip: 'Ver detalhes',
          onPressed: () {
            L.d('[GridList] abrir detalhes do item ${getNestedValue(item, widget.idFieldName)}');
            if (widget.detailScreenBuilder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => widget.detailScreenBuilder!(item)),
              );
            } else {
              _openDetailPage(item);
            }
          },
        ),
      if (_can('edit') && widget.hasPermission('edit'))
        iconBtn(
          icon: Icons.edit_outlined,
          color: GridColors.primary,
          tooltip: 'Editar',
          onPressed: () async {
            final ok = await _confirm(
              title: 'Editar',
              message: 'Deseja abrir o formulário para editar o item?',
              confirmText: 'Abrir',
            );
            if (ok == true) {
              _openForm(editingItem: item);
            }
          },
        ),
      if (_can('delete') && widget.hasPermission('delete'))
        iconBtn(
          icon: Icons.delete_outline,
          color: GridColors.error,
          tooltip: 'Excluir',
          onPressed: () =>
              _deleteItem(getNestedValue(item, widget.idFieldName).toString()),
        ),
      ...perItemServer.map(
        (a) => iconBtn(
          icon: a.icon ?? Icons.play_arrow,
          color: GridColors.secondary,
          tooltip: a.label,
          onPressed: () => _runServerAction(context, a, item),
        ),
      ),
      ..._customActions
          .where((a) => a.isVisible == null || a.isVisible!(item))
          .map(
            (a) => iconBtn(
              icon: a.icon,
              color: GridColors.secondary,
              tooltip: a.label,
              onPressed: () => a.onPressed(context, item),
            ),
          ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // CRUD / Server Actions
  // ---------------------------------------------------------------------------
  Future<void> _openForm({Map<String, dynamic>? editingItem}) async {
    L.i('[GridList] open form (editing=${editingItem != null})');
    final saved = await showDialog<bool>(
      context: context,
      barrierColor: GridColors.primary.withValues(alpha: 0.7),
      builder: (ctx) => GridFormDialog(
        titleNew: 'Adicionar',
        titleEdit: 'Editar',
        fieldConfigs: widget.fieldConfigs,
        createEndpoint: widget.createEndpoint,
        updateEndpoint: widget.updateEndpoint,
        authHeadersProvider: widget.authHeadersProvider,
        baseUrlForMultipart: widget.baseUrlForMultipart,
        additionalFormData: widget.additionalFormData,
        dynamicAdditionalFormData: widget.dynamicAdditionalFormData,
        transformFormData: widget.transformFormData,
        editingItem: editingItem,
        idFieldName: widget.idFieldName,
      ),
    );
    if (saved == true) await _load(reset: true);
  }

  Future<void> _deleteItem(String id) async {
    try {
      final doDelete = await _confirm(
        title: 'Excluir',
        message: 'Deseja excluir o item #$id? Esta ação não pode ser desfeita.',
        confirmText: 'Excluir',
      );
      if (doDelete != true) return;

      L.w('[GridList] DELETE ${widget.deleteEndpoint} id=$id');
      final resp = await NetworkCaller().deleteRequest(
        widget.deleteEndpoint.replaceFirst(':id', id),
      );
      if (resp.isSuccess) {
        _snack('Item excluído!');
        L.s('[GridList] item excluido: $id');
        await _load(reset: true);
      } else {
        _snack('Erro ao excluir: ${resp.statusCode}', true);
      }
    } catch (e, st) {
      L.e('[GridList] delete exception: $e\n$st');
      _snack('Erro ao excluir: $e', true);
    }
  }

  Future<void> _runServerAction(BuildContext context, ServerAction action,
      Map<String, dynamic>? item) async {
    final msg = action.confirmMessage?.trim().isNotEmpty == true
        ? action.confirmMessage!
        : 'Deseja realmente executar "${action.label}"?';
    final ok = await _confirm(
      title: action.label,
      message: msg,
      confirmText: 'Executar',
    );
    if (ok != true) return;

    try {
      final endpoint = item == null
          ? action.endpoint
          : action.endpoint.replaceFirst(
              ':id', (getNestedValue(item, widget.idFieldName)).toString());

      L.i('[GridList] ServerAction ${action.method} $endpoint');
      NetworkResponse resp;
      switch (action.method.toUpperCase()) {
        case 'GET':
          resp = await NetworkCaller().getRequest(endpoint);
          break;
        case 'POST':
          resp = await NetworkCaller().postRequest(endpoint, const {});
          break;
        case 'PUT':
          resp = await NetworkCaller().putRequest(endpoint, const {});
          break;
        case 'DELETE':
          resp = await NetworkCaller().deleteRequest(endpoint);
          break;
        default:
          _snack('Método não suportado: ${action.method}', true);
          return;
      }

      if (resp.isSuccess) {
        _snack('Ação "${action.label}" executada com sucesso!');
        L.s('[GridList] acao "${action.label}" executada');
        await _load(reset: true);
      } else {
        _snack('Falha em "${action.label}": ${resp.statusCode}', true);
      }
    } catch (e, st) {
      L.e('[GridList] server action error: $e\n$st');
      _snack('Erro ao executar ação: $e', true);
    }
  }

  // ---------------------------------------------------------------------------
  // Seleção múltipla
  // ---------------------------------------------------------------------------
  void _toggleSelectionMode() {
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) {
        _sel.clear();
      }
    });
  }

  void _toggleSel(String id, bool selected) {
    setState(() {
      if (selected) {
        _sel[id] = true;
      } else {
        _sel.remove(id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      for (final it in _filtered) {
        final id = (getNestedValue(it, widget.idFieldName) ?? '').toString();
        _sel[id] = true;
      }
    });
  }

  void _deselectAll() {
    setState(() => _sel.clear());
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Excluir ${_sel.length} item(s)?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final id in _sel.keys.toList()) {
                await _deleteItem(id);
              }
              setState(() {
                _sel.clear();
                _selectionMode = false;
              });
              await _load(reset: true);
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📄 Página de Detalhes com Exportação PDF
  // ---------------------------------------------------------------------------

  void _openDetailPage(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DetailPage(
          titulo: widget.title,
          item: item,
          fieldConfigs: widget.fieldConfigs,
          idFieldName: widget.idFieldName,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Outras UIs utilitárias
  // ---------------------------------------------------------------------------
  void _showAllFieldsDebug(BuildContext context, Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(children: [
            const Text('DEBUG - JSON do item',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Text(const JsonEncoder.withIndent('  ').convert(item)),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fechar')),
          ]),
        ),
      ),
    );
  }

  void _showFieldSettings() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Campos visíveis'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: widget.fieldConfigs.map((c) {
                return CheckboxListTile(
                  title: Text(c.label),
                  value: _fieldVisibility[c.fieldName] ?? c.isVisibleByDefault,
                  onChanged: c.isFixed
                      ? null
                      : (v) {
                          setSt(() {
                            _fieldVisibility[c.fieldName] = v ?? false;
                          });
                        },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(GridTexts.cancel)),
            ElevatedButton(
              onPressed: () async {
                await _saveFieldPreferences();
                _notifyCustomizationState();
                Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              child: const Text('Aplicar'),
            ),
          ],
        );
      }),
    );
  }

  Future<bool?> _confirm({
    required String title,
    required String message,
    String confirmText = 'Confirmar',
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(GridTexts.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, [bool error = false]) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? GridColors.error : GridColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Barra de ações de servidor (acima da lista) — ADICIONADA
  // ---------------------------------------------------------------------------
  Widget _buildServerActionsBar(BuildContext context) {
    final actions = (widget.serverActions ?? const <ServerAction>[])
        .where((a) => !a.endpoint.contains(':id'))
        .toList();
    if (actions.isEmpty) return const SizedBox.shrink();

    final visible = actions.where((a) {
      final perm = a.requiredPermission;
      if (perm == null || perm.isEmpty) return true;
      return _can(perm);
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: visible.map((a) {
          return ElevatedButton.icon(
            icon: Icon(a.icon ?? Icons.play_arrow),
            label: Text(a.label),
            onPressed: () => _runServerAction(context, a, null),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// GridFormManager (stub) — ADICIONADO
// Futuramente você pode substituir por um Dialog real do seu grid_form.
// ---------------------------------------------------------------------------
class GridFormManager {
  final BuildContext context;
  final List<FieldConfig> fieldConfigs;
  final String createEndpoint;
  final String updateEndpoint;
  final Map<String, dynamic>? additionalFormData;
  final Map<String, dynamic> Function(Map<String, dynamic>? item)?
      dynamicAdditionalFormData;
  final String idFieldName;

  GridFormManager({
    required this.context,
    required this.fieldConfigs,
    required this.createEndpoint,
    required this.updateEndpoint,
    this.additionalFormData,
    this.dynamicAdditionalFormData,
    required this.idFieldName,
  });

  Future<void> open({Map<String, dynamic>? editingItem}) async {
    L.i('[GridFormManager] open (editing=${editingItem != null})');
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editingItem != null ? 'Editar' : 'Novo'),
        content: const Text(
            'Aqui será exibido o formulário (GridFormDialog ou equivalente).'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(GridTexts.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(GridTexts.save),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 📄 Página de detalhes de um item com exportação PDF
// -----------------------------------------------------------------------------
class _DetailPage extends StatelessWidget {
  final String titulo;
  final Map<String, dynamic> item;
  final List<FieldConfig> fieldConfigs;
  final String idFieldName;

  const _DetailPage({
    required this.titulo,
    required this.item,
    required this.fieldConfigs,
    required this.idFieldName,
  });

  @override
  Widget build(BuildContext context) {
    final visibleFields =
        fieldConfigs.where((f) => f.isInForm || f.showInCard).toList();

    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context, visibleFields),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: visibleFields.map((f) => _buildFieldCard(f)).toList(),
        ),
      ),
    );
  }

  Widget _buildFieldCard(FieldConfig campo) {
    final valor = _resolveValue(campo);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: GridColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              campo.icon ?? Icons.label_outline,
              size: 18,
              color: GridColors.secondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campo.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GridColors.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    valor,
                    style: const TextStyle(
                      fontSize: 14,
                      color: GridColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveValue(FieldConfig campo) {
    dynamic raw = getNestedValue(item, campo.fieldName);
    if (raw == null) return '—';

    if (campo.fieldType == FieldType.boolean) {
      return raw == true || raw == 'true' ? 'Sim' : 'Não';
    }
    if (campo.fieldType == FieldType.date) {
      try {
        final dt = DateTime.parse(raw.toString());
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      } catch (_) {}
    }
    if (campo.fieldType == FieldType.dropdown) {
      final displayField = campo.displayFieldName ?? campo.dropdownDisplayField;
      if (raw is Map && raw.containsKey(displayField)) {
        return raw[displayField].toString();
      }
      final options = campo.dropdownOptions ?? [];
      for (final opt in options) {
        if (opt[campo.dropdownValueField].toString() == raw.toString()) {
          return opt[displayField]?.toString() ?? raw.toString();
        }
      }
    }
    return raw.toString();
  }

  Future<void> _exportPdf(
      BuildContext context, List<FieldConfig> campos) async {
    final doc = pw.Document();

    final linhas = campos
        .map((f) => MapEntry(f.label, _resolveValue(f)))
        .where((e) => e.value != '—')
        .toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.green900),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Campo',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          'Valor',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...linhas.asMap().entries.map((entry) {
                    final par = entry.key.isEven;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: par ? PdfColors.grey50 : PdfColors.white,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            entry.value.key,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            entry.value.value,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    final Uint8List bytes = await doc.save();
    if (!context.mounted) return;

    await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: '$titulo.pdf',
    );
  }
}

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/auth_utility.dart';
import '../services/favorites_service.dart';
import '../services/permission_service.dart';
import '../utils/menu_config.dart';
import '../utils/security_matrix.dart';
import '../utils/string_utils.dart';
import '../utils/asset_loader.dart';

/// Sidebar com submenus, busca e favoritos.
/// Usado tanto no Windows quanto no Web (drawer).
class AppSidebar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<MenuItem> onSelect;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int unreadAlerts;
  final VoidCallback onNotificationTap;
  final VoidCallback onLogout;
  final String userName;
  final String userEmail;

  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.unreadAlerts,
    required this.onNotificationTap,
    required this.onLogout,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  static const _primary = GridColors.primary; // Sage Sereno (#3E6B5C)
  static const _bg = GridColors.primaryDark; // Sage Profundo (#2D5246)
  static const _bgItem = Color(0xFF355E51); // Hover Sage
  static const _bgSelected = Color(0xFF244339); // Selecionado Sage Profundo
  static const _textColor = Colors.white; // Branco
  static const _textMuted = Color(0xFFCBD5E1); // Ardósia Suave


  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Set<String> _favorites = {};
  final Set<String> _expandedGroups = {};
  String _userId = '';
  bool _disposed = false;

  // Permissão: ids de tela liberados. `null` = mostrar tudo (MASTER ou
  // anti-lockout — ver SecurityMatrix.allowedTelaIds).
  Set<String>? _allowedIds;

  /// true se o item pode aparecer no menu para o usuario logado.
  bool _canSee(MenuItem item) {
    // Itens exclusivos do dono do sistema (wlclimaco@gmail.com).
    const ownerOnly = {'match', 'timeline', 'instagram_monitor'};
    if (ownerOnly.contains(item.id)) {
      final email = widget.userEmail.toLowerCase();
      return email == 'wlclimaco@gmail.com';
    }
    // Achado de code review (2026-09-11): 'sessoes' (matar sessao de
    // usuario) nao esta mapeado em PermissionService._getTelaNomeForMenuItem
    // -- por isso canViewScreen('sessoes') sempre retorna false e a
    // visibilidade cairia inteiramente no fallback legado de
    // _allowedIds (MASTER/anti-lockout = mostra tudo; senao, catalogo
    // dinamico do backend). O backend ja restringe os 4 endpoints de
    // /api/sessoes a MASTER (@PreAuthorize isMaster()), mas o Flutter nao
    // tinha barreira propria -- se o catalogo dinamico algum dia ganhar
    // uma linha "Sessoes" pra outra role (seed, erro humano no Controle de
    // Acesso), o item ficaria visivel/clicavel ate' o 403 no clique, sem
    // feedback preventivo. Guard explicito aqui, no mesmo espirito do
    // ownerOnly acima.
    const masterOnly = {'sessoes'};
    if (masterOnly.contains(item.id)) {
      return SecurityMatrix.current().isMaster;
    }

    // MASTER / SYSTEM tem acesso total (respeitando módulo se configurado)
    if (SecurityMatrix.current().isMaster) {
      return ModuloAccess.isMenuItemAllowed(item.id);
    }

    // 1. Checagem de Módulo Contratado (idêntico ao Mobile):
    if (!ModuloAccess.isMenuItemAllowed(item.id)) {
      return false;
    }

    // 2. Permissões dinâmicas da Role via PermissionService (RBAC do backend):
    if (PermissionService().hasPermissoes) {
      return PermissionService().canViewScreen(item.id);
    }

    // 3. Fallback: manter compatibilidade com SecurityMatrix (módulos legados quando sem permissões do backend)
    // Converte item.id (snake_case) para camelCase para comparar com telaNome (backend).
    final camelCaseId = StringUtils.snakeToCamelCase(item.id);
    return _allowedIds == null || _allowedIds!.contains(camelCaseId);
  }

  @override
  void initState() {
    super.initState();
    _computeAllowed();
    _applyDefaultExpansion();
    _loadFavorites();
    _searchCtrl.addListener(() {
      if (mounted && !_disposed) setState(() => _searchQuery = _searchCtrl.text);
    });
  }

  @override
  void didUpdateWidget(covariant AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.userEmail != widget.userEmail) {
      _computeAllowed();
      _applyDefaultExpansion();
    }
  }

  /// Grupos com pelo menos um item visível ao usuário (após filtro de módulo/
  /// permissão). É o conjunto que de fato aparece no menu.
  List<MenuGroup> _visibleGroups() =>
      MenuConfig.groups.where((g) => g.items.any(_canSee)).toList();

  /// Colapso adaptativo (iniciativa "Acesso por Módulo do Cliente", spec UI):
  ///  - 1 grupo visível  → itens renderizados flat (sem cabeçalho), tratado no
  ///    build; nada a expandir aqui.
  ///  - 2 grupos         → ambos abertos por padrão.
  ///  - 3+ grupos        → tudo colapsado, exceto o grupo do item selecionado.
  void _applyDefaultExpansion() {
    final visibles = _visibleGroups();
    _expandedGroups.clear();
    if (visibles.length == 2) {
      for (final g in visibles) {
        _expandedGroups.add(g.id);
      }
    } else if (visibles.length >= 3) {
      for (final g in visibles) {
        if (g.items.any((i) => i.screenIndex == widget.selectedIndex)) {
          _expandedGroups.add(g.id);
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _searchCtrl.dispose();
    super.dispose();
  }

  void _computeAllowed() {
    // Converte ids dos itens de menu (snake_case) para camelCase para corresponder
    // aos nomes de telas do SecurityMatrix
    final allMenuIds = MenuConfig.allItems
        .map((m) => StringUtils.snakeToCamelCase(m.id))
        .toSet();
    _allowedIds = SecurityMatrix.current().allowedTelaIds(allMenuIds);
  }

  Future<void> _loadFavorites() async {
    _userId = AuthUtility.userInfo?.data?.id?.toString() ?? 'guest';
    final favs = await FavoritesService.load(_userId);
    if (mounted && !_disposed) setState(() => _favorites = favs);
  }

  Future<void> _toggleFavorite(String itemId) async {
    final newState = await FavoritesService.toggle(_userId, itemId);
    if (mounted && !_disposed) setState(() {
      if (newState) {
        _favorites.add(itemId);
      } else {
        _favorites.remove(itemId);
      }
    });
  }

  void _toggleGroup(String groupId) {
    if (mounted && !_disposed) setState(() {
      if (_expandedGroups.contains(groupId)) {
        _expandedGroups.remove(groupId);
      } else {
        _expandedGroups.add(groupId);
      }
    });
  }

  void _navigate(MenuItem item) {
    if (item.screenIndex >= 0) {
      widget.onSelect(item);
    }
  }

  bool get _isSearching => _searchQuery.trim().isNotEmpty;

  List<MenuItem> get _favoriteItems {
    return MenuConfig.allItems
        .where((m) => _favorites.contains(m.id) && _canSee(m))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  /// Decodifica a foto do usuário (base64) vinda do login ou dos dados pessoais.
  /// Suporta strings que já trazem prefixo "data:image/...;base64," do backend.
  /// Fix WR-04: usa MIME type genérico `image/*` para suportar PNG, JPEG, etc.
  Uint8List _getUserAvatar() {
    final raw = AuthUtility.userInfo?.login?.foto ??
        AuthUtility.userInfo?.data?.codDadosPessoal?.photo;
    if (raw == null || raw.trim().isEmpty) return Uint8List(0);
    try {
      final base64Only = raw.contains(';base64,')
          ? raw.substring(raw.indexOf(';base64,') + 8)
          : raw.trim();
      // Usa generic MIME type para suportar múltiplos formatos de imagem
      final UriData? data =
          Uri.parse('data:image/*;base64,$base64Only').data;
      if (data != null) return data.contentAsBytes();
    } catch (_) {}
    return Uint8List(0);
  }

  /// Nome da empresa ou parceiro do usuário logado.
  /// Se o usuário possui parceiro vinculado (parceiro != null), exibe o nome do parceiro.
  /// Se parceiro for null (usuário interno/master), exibe o nome da empresa.
  /// Bug de producao (2026-09-11): a ordem anterior (empresa antes de
  /// parceiro) regredia essa regra. Alinhado com a implementacao ja
  /// existente e correta em task_manager_flutter_merged_final.
  String _getCompanyName() {
    final login =
        AuthUtility.userInfo?.login ?? AuthUtility.userInfo?.data?.login;
    final parceiro = login?.parceiro;
    if (parceiro != null) {
      if (parceiro.nome != null && parceiro.nome!.trim().isNotEmpty) {
        return parceiro.nome!.trim();
      }
      if (parceiro.razaoSocial != null &&
          parceiro.razaoSocial!.trim().isNotEmpty) {
        return parceiro.razaoSocial!.trim();
      }
      if (login?.nome != null && login!.nome!.trim().isNotEmpty) {
        return login.nome!.trim();
      }
      return '';
    }
    final empresa = login?.empresa;
    if (empresa != null) {
      if (empresa.nome != null && empresa.nome!.trim().isNotEmpty) {
        return empresa.nome!.trim();
      }
      if (empresa.razaoSocial != null &&
          empresa.razaoSocial!.trim().isNotEmpty) {
        return empresa.razaoSocial!.trim();
      }
    }
    return '';
  }

  /// Inicial para o avatar: usa o email (sempre disponível) em vez do nome.
  /// Strategy email-first: garante consistência visual entre plataformas.
  /// Fix WR-02: evita divergência cliente vs web de avatar initial.
  String _avatarInitial() {
    final email = widget.userEmail;
    if (email.isNotEmpty) return email[0].toUpperCase();
    final name = widget.userName;
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.isCollapsed ? 64 : 260,
      decoration: BoxDecoration(
        color: _bg,
        border:
            const Border(right: BorderSide(color: Color(0xFF004a20), width: 1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(2, 0))
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (!widget.isCollapsed) _buildSearch(),
          Expanded(
            child: widget.isCollapsed
                ? _buildCollapsedList()
                : _isSearching
                    ? _buildSearchResults()
                    : _buildFullMenu(),
          ),
          _buildCollapseButton(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  // Avatar do usuário: foto real (mesma fonte do UserBannerAppBar) com
  // fallback para a inicial do nome quando não há foto cadastrada.
  Widget _buildUserAvatar(double radius) {
    final avatar = _getUserAvatar();
    final initial = _avatarInitial();
    final fallback = Text(
      initial,
      style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.8),
    );
    return CircleAvatar(
      radius: radius,
      backgroundColor: _primary,
      child: avatar.isNotEmpty
          ? ClipOval(
              child: Image.memory(
                avatar,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
            )
          : fallback,
    );
  }

  Widget _buildHeader() {
    if (widget.isCollapsed) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            // Logo Abraço Contabilidade (versão compacta — só o avatar/ícone)
            ClipOval(
              child: AssetLoader.loadImage(
                'assets/images/logo_contabilidade.jpg',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            _buildUserAvatar(18),
            const SizedBox(height: 8),
            _iconBtn(
                Icons.notifications,
                widget.unreadAlerts > 0 ? _primary : _textMuted,
                widget.onNotificationTap,
                badge: widget.unreadAlerts),
            const SizedBox(height: 4),
            _iconBtn(Icons.logout, _textMuted, widget.onLogout),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF004a20), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo da Abraço Contabilidade
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AssetLoader.loadImage(
                  'assets/images/logo_contabilidade.jpg',
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Abraço Contabilidade',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: _textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildUserAvatar(20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha 1: email (identificador principal do usuário)
                    Text(
                      widget.userEmail.isNotEmpty
                          ? widget.userEmail
                          : widget.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    // Linha 2: empresa ou cliente logado
                    if (_getCompanyName().isNotEmpty)
                      Text(
                        _getCompanyName(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: _textMuted, fontSize: 11),
                      ),
                  ],
                ),
              ),
              _iconBtn(
                  Icons.notifications,
                  widget.unreadAlerts > 0 ? _primary : _textMuted,
                  widget.onNotificationTap,
                  badge: widget.unreadAlerts),
              const SizedBox(width: 4),
              _iconBtn(Icons.logout, _textMuted, widget.onLogout),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap,
      {int badge = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, color: color, size: 18),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  // ── Busca ─────────────────────────────────────────────────────────────────
  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: _textColor, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Buscar tela...',
          hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: _textMuted, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () => _searchCtrl.clear(),
                  child: const Icon(Icons.close, color: _textMuted, size: 16),
                )
              : null,
          filled: true,
          fillColor: _bgItem,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  // ── Resultados de busca ───────────────────────────────────────────────────
  Widget _buildSearchResults() {
    final results = MenuConfig.search(_searchQuery).where(_canSee).toList();
    if (results.isEmpty) {
      return const Center(
          child: Text('Nenhuma tela encontrada',
              style: TextStyle(color: _textMuted, fontSize: 12)));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children:
          results.map((item) => _buildMenuItem(item, indent: false)).toList(),
    );
  }

  // ── Menu completo ─────────────────────────────────────────────────────────
  Widget _buildFullMenu() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        // Favoritos
        if (_favoriteItems.isNotEmpty) ...[
          _buildSectionHeader('⭐ Favoritos'),
          ..._favoriteItems.map((item) => _buildMenuItem(item, indent: true)),
          const Divider(color: Color(0xFF004a20), height: 16),
        ],
        // Grupos por módulo — colapso adaptativo. Com 1 só grupo visível,
        // renderiza os itens direto (sem cabeçalho), evitando ruído quando o
        // cliente tem um único módulo.
        if (_visibleGroups().length == 1)
          ..._visibleGroups()
              .first
              .items
              .where(_canSee)
              .map((item) => _buildMenuItem(item, indent: true))
        else
          ..._visibleGroups().map((group) => _buildGroup(group)),
        // Itens soltos
        if (MenuConfig.loose.any(_canSee)) ...[
          const Divider(color: Color(0xFF004a20), height: 16),
          _buildSectionHeader('Outros'),
          ...MenuConfig.loose
              .where(_canSee)
              .map((item) => _buildMenuItem(item, indent: true)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Text(title.toUpperCase(),
          style: const TextStyle(
              color: _textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8)),
    );
  }

  Widget _buildGroup(MenuGroup group) {
    final isExpanded = _expandedGroups.contains(group.id);
    // Verifica se algum item do grupo está selecionado
    final hasSelected =
        group.items.any((i) => i.screenIndex == widget.selectedIndex);
    // Verifica se algum item do grupo é favorito
    final hasFavorite = group.items.any((i) => _favorites.contains(i.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do grupo
        InkWell(
          onTap: () => _toggleGroup(group.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: hasSelected
                  ? _bgSelected.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
            child: Row(
              children: [
                FaIcon(group.icon,
                    size: 14, color: hasSelected ? _primary : _textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(group.label,
                      style: TextStyle(
                        color: hasSelected ? _primary : _textColor,
                        fontSize: 13,
                        fontWeight:
                            hasSelected ? FontWeight.w700 : FontWeight.w500,
                      )),
                ),
                if (hasFavorite)
                  const Icon(Icons.star, size: 10, color: Colors.amber),
                const SizedBox(width: 4),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _textMuted,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // Itens do grupo (apenas os visíveis)
        if (isExpanded)
          ...group.items
              .where(_canSee)
              .map((item) => _buildMenuItem(item, indent: true)),
      ],
    );
  }

  Widget _buildMenuItem(MenuItem item, {required bool indent}) {
    final isSelected =
        item.screenIndex == widget.selectedIndex && item.screenIndex >= 0;
    final isFav = _favorites.contains(item.id);

    return InkWell(
      onTap: item.screenIndex >= 0 ? () => _navigate(item) : null,
      child: Container(
        padding: EdgeInsets.only(
          left: indent ? 32 : 14,
          right: 8,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? _bgSelected : Colors.transparent,
          border: isSelected
              ? const Border(left: BorderSide(color: _primary, width: 3))
              : null,
        ),
        child: Row(
          children: [
            FaIcon(item.icon,
                size: 13,
                color: isSelected
                    ? _primary
                    : item.screenIndex < 0
                        ? _textMuted.withValues(alpha: 0.5)
                        : _textMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(item.label,
                  style: TextStyle(
                    color: isSelected
                        ? _primary
                        : item.screenIndex < 0
                            ? _textMuted.withValues(alpha: 0.5)
                            : _textColor,
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
            // Estrela de favorito
            GestureDetector(
              onTap: () => _toggleFavorite(item.id),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  size: 14,
                  color:
                      isFav ? Colors.amber : _textMuted.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lista colapsada (só ícones) ───────────────────────────────────────────
  Widget _buildCollapsedList() {
    final allItems = [
      ...MenuConfig.groups.expand((g) => g.items),
      ...MenuConfig.loose
    ];
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children:
          allItems.where((i) => i.screenIndex >= 0 && _canSee(i)).map((item) {
        final isSelected = item.screenIndex == widget.selectedIndex;
        return Tooltip(
          message: item.label,
          preferBelow: false,
          child: InkWell(
            onTap: () => _navigate(item),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? _bgSelected : Colors.transparent,
                border: isSelected
                    ? const Border(left: BorderSide(color: _primary, width: 3))
                    : null,
              ),
              child: Center(
                child: FaIcon(item.icon,
                    size: 16, color: isSelected ? _primary : _textMuted),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Botão colapsar ────────────────────────────────────────────────────────
  Widget _buildCollapseButton() {
    return InkWell(
      onTap: widget.onToggleCollapse,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF004a20))),
        ),
        child: Center(
          child: Icon(
            widget.isCollapsed ? Icons.chevron_right : Icons.chevron_left,
            color: _textMuted,
            size: 20,
          ),
        ),
      ),
    );
  }
}

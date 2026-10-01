import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/alert_model.dart';
import '../../../models/auth_utility.dart';
import '../../services/alert_caller.dart';
import '../../../auth_screens/login_screen.dart';
import 'package:task_manager_flutter/mobile/screens/meu_perfil_screen.dart';
import 'meu_perfil_dialog.dart';
import '../../../utils/grid_colors.dart'; // ★ adicionado para aplicar o tema
import '../../../utils/asset_loader.dart';

// AppBar customizado (apenas cabeçalho)
class UserBannerAppBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback? onTapped;
  final String? screenTitle;
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onEmpresaTap;
  final VoidCallback? onUserTap;
  final VoidCallback? onFilterToggle;
  final VoidCallback? onColumns;
  final bool? showFilterButton;

  /// Botoes de acao especificos da tela (ex.: salvar), exibidos antes dos
  /// icones fixos de notificacoes e logout no header.
  final List<Widget>? actions;

  /// Exibe uma seta de voltar no inicio do header. Use em sub-paginas abertas
  /// via Navigator.push (edicao/detalhe) que precisam voltar.
  final bool showBackButton;

  /// Substitui a FilterActionBar padrão por uma barra inferior própria (ex.:
  /// toggle Dia/Mês/Ano do Calendário Financeiro). Quando informado, ignora
  /// showFilterButton/onFilterToggle/onColumns/onRefresh — quem passa um
  /// bottom customizado é responsável pelo próprio refresh/filtro/etc.
  final PreferredSizeWidget? customBottom;

  const UserBannerAppBar({
    super.key,
    this.onTapped,
    this.screenTitle,
    this.onRefresh,
    this.isLoading,
    this.onEmpresaTap,
    this.onUserTap,
    this.onFilterToggle,
    this.onColumns,
    this.showFilterButton = true,
    this.actions,
    this.showBackButton = false,
    this.customBottom,
  });

  @override
  _UserBannerAppBarState createState() => _UserBannerAppBarState();

  @override
  Size get preferredSize {
    const baseHeight = kToolbarHeight;
    if (customBottom != null) {
      return Size.fromHeight(baseHeight + customBottom!.preferredSize.height);
    }
    // Ajusta a altura baseada no showFilterButton
    final filterBarHeight = (showFilterButton == true) ? 52.0 : 0.0;
    return Size.fromHeight(baseHeight + filterBarHeight);
  }
}

class _UserBannerAppBarState extends State<UserBannerAppBar> {
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  OverlayEntry? notificationOverlay;
  Timer? _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startPeriodicFetch();
  }

  void _startPeriodicFetch() {
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    try {
      if (AuthUtility.isLoggedIn) {
        final List<Alert> alertData =
            await AlertCaller().fetchNotificacoes(context);
        if (mounted && !_disposed) {
          setState(() {
            notifications = alertData;
            unreadAlerts = notifications.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(int id) async {
    final notificacao = notifications.where((n) => n.id == id).firstOrNull;
    if (notificacao == null) return;

    final sucesso = await AlertCaller().marcarNotificacaoLida(notificacao);
    if (!sucesso) {
      _mostrarErroNotificacao(
          'Não foi possível marcar a notificação como lida.');
      return;
    }
    if (mounted && !_disposed) {
      setState(() {
        notifications.removeWhere((n) => n.id == id);
        unreadAlerts = notifications.length;
      });
    }
  }

  Future<void> deleteNotification(int id) async {
    final notificacao = notifications.where((n) => n.id == id).firstOrNull;
    if (notificacao == null) return;

    final sucesso = await AlertCaller().marcarNotificacaoLida(notificacao);
    if (!sucesso) {
      _mostrarErroNotificacao('Não foi possível excluir a notificação.');
      return;
    }
    if (mounted && !_disposed) {
      setState(() {
        notifications.removeWhere((n) => n.id == id);
        unreadAlerts = notifications.length;
      });
    }
  }

  void _mostrarErroNotificacao(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: GridColors.error),
    );
  }

  String? _formatNotificationDate(String? data) {
    if (data == null || data.isEmpty) return null;
    final parsed = DateTime.tryParse(data);
    if (parsed == null) return null;
    return DateFormat('dd/MM/yyyy HH:mm').format(parsed);
  }

  Future<void> deleteAllNotifications() async {
    final sucesso = await AlertCaller().marcarTodasNotificacoesLidas();
    if (!sucesso) {
      _mostrarErroNotificacao(
          'Não foi possível marcar todas as notificações como lidas.');
      return;
    }
    if (mounted && !_disposed) {
      setState(() {
        notifications.clear();
        unreadAlerts = 0;
      });
    }
  }

  /// Retorna ícone e cor representando o tipo de notificação.
  _NotificationTipoMeta _resolverTipo(String status) {
    final s = status.toUpperCase();
    if (s.contains('ALVAR') || s.contains('CERTID')) {
      return _NotificationTipoMeta(
          Icons.verified_outlined, GridColors.warning, 'Documento');
    }
    if (s.contains('VENC') || s.contains('PRAZO')) {
      return _NotificationTipoMeta(
          Icons.schedule_outlined, GridColors.error, 'Vencimento');
    }
    if (s.contains('CHAT') || s.contains('MENSAG')) {
      return _NotificationTipoMeta(
          Icons.chat_bubble_outline, GridColors.info, 'Mensagem');
    }
    if (s.contains('GED') || s.contains('ARQUIVO')) {
      return _NotificationTipoMeta(
          Icons.attach_file_outlined, GridColors.secondary, 'Arquivo');
    }
    if (s.contains('COMUNICADO')) {
      return _NotificationTipoMeta(
          Icons.campaign_outlined, GridColors.primaryLight, 'Comunicado');
    }
    return _NotificationTipoMeta(
        Icons.notifications_outlined, GridColors.primary, 'Aviso');
  }

  /// Formata data relativa: "agora", "há 2h", "ontem", "dd/MM".
  String _dataRelativa(String? data) {
    if (data == null || data.isEmpty) return '';
    final parsed = DateTime.tryParse(data);
    if (parsed == null) return '';
    final diff = DateTime.now().difference(parsed);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return DateFormat('dd/MM').format(parsed);
  }

  void _safeRemoveOverlay() {
    try {
      notificationOverlay?.remove();
    } catch (_) {}
    notificationOverlay = null;
  }

  void showNotificationDropdown(BuildContext context) {
    if (notificationOverlay != null) {
      _safeRemoveOverlay();
      return;
    }

    // Mobile: usa bottom sheet; desktop/web: overlay posicionado
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (isMobile) {
      _mostrarBottomSheet(context);
      return;
    }

    final overlay = Overlay.of(context);
    // Usa preferredSize (já soma kToolbarHeight + altura do bottom, seja
    // FilterActionBar ou customBottom) em vez de reimplementar a conta —
    // evitava desalinhar o dropdown quando customBottom tem altura diferente
    // de 52 (ex.: 44 no Calendário Financeiro).
    final hasBottomBar =
        widget.customBottom != null || widget.showFilterButton == true;
    final topOffset = widget.preferredSize.height + (hasBottomBar ? 16 : 12);

    notificationOverlay = OverlayEntry(
      builder: (ctx) {
        // Bloqueia overlay preso se o builder lançar exceção
        try {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _safeRemoveOverlay,
            child: Stack(
              children: [
                Positioned(
                  top: topOffset,
                  right: 8,
                  child: GestureDetector(
                    onTap: () {}, // impede fechar ao clicar no painel
                    child: _NotificationPanel(
                      notifications: notifications,
                      onMarcarLida: (id) {
                        markNotificationAsRead(id);
                        _safeRemoveOverlay();
                      },
                      onDeletar: (id) {
                        deleteNotification(id);
                        _safeRemoveOverlay();
                      },
                      onMarcarTodas: () {
                        deleteAllNotifications();
                        _safeRemoveOverlay();
                      },
                      onFechar: _safeRemoveOverlay,
                      resolverTipo: _resolverTipo,
                      dataRelativa: _dataRelativa,
                    ),
                  ),
                ),
              ],
            ),
          );
        } catch (_) {
          _safeRemoveOverlay();
          rethrow;
        }
      },
    );

    overlay.insert(notificationOverlay!);
  }

  void _mostrarBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (__, scrollController) => Container(
          decoration: const BoxDecoration(
            color: GridColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Alça de drag
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GridColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _NotificationPanel(
                  notifications: notifications,
                  onMarcarLida: (id) => markNotificationAsRead(id),
                  onDeletar: (id) => deleteNotification(id),
                  onMarcarTodas: () => deleteAllNotifications(),
                  onFechar: () => Navigator.pop(context),
                  resolverTipo: _resolverTipo,
                  dataRelativa: _dataRelativa,
                  scrollController: scrollController,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    AuthUtility.clearUserInfo();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Uint8List _getUserAvatar() {
    final base64String = AuthUtility.userInfo?.login?.foto ??
        AuthUtility.userInfo?.data?.codDadosPessoal?.photo;
    if (base64String != null && base64String.trim().isNotEmpty) {
      try {
        final UriData? data =
            Uri.parse("data:image/png;base64,$base64String").data;
        if (data != null) return data.contentAsBytes();
      } catch (_) {}
    }
    return Uint8List(0);
  }

  /// Bug de producao (2026-09-11): regra ja documentada em bugs.md/CLAUDE.md
  /// -- se o login tem parceiro, o subtitulo tem que ser o nome do PARCEIRO
  /// (cliente da contabilidade), nunca o nome da empresa/tenant. A ordem
  /// empresa->parceiro anterior regrediu essa regra: um usuario vinculado a
  /// um parceiro/cliente aparecia com o nome da contabilidade (empresa)
  /// embaixo do avatar, igual a qualquer usuario interno/master. Alinhado
  /// com a implementacao ja existente e correta em
  /// task_manager_flutter_merged_final.
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

  String _getUserName() {
    return AuthUtility.userInfo?.login?.nome ??
        AuthUtility.userInfo?.data?.codDadosPessoal?.nome ??
        '';
  }

  String _avatarInitial() {
    final email = AuthUtility.userInfo?.login?.email ?? '';
    if (email.isNotEmpty) return email[0].toUpperCase();
    final name = _getUserName();
    if (name.isNotEmpty) return name[0].toUpperCase();
    return 'U';
  }

  @override
  void dispose() {
    _disposed = true;
    _safeRemoveOverlay();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthUtility.isLoggedIn;

    return AppBar(
      backgroundColor: GridColors.primary,
      automaticallyImplyLeading: false,
      leading: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: GridColors.textPrimary),
              onPressed: () => Navigator.maybePop(context),
              tooltip: 'Voltar',
            )
          : null,
      title: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 120,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoggedIn) ...[
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo do escritório
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: AssetLoader.loadImageWithCustomError(
                        'assets/images/logo_contabilidade.jpg',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(width: 28, height: 28),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // CORREÇÃO: GestureDetector apenas no CircleAvatar
                    GestureDetector(
                      onTap: () {
                        if (widget.onUserTap != null) {
                          widget.onUserTap!();
                          return;
                        }
                        if (MediaQuery.of(context).size.width < 700) {
                          Navigator.of(context)
                              .push(
                            MaterialPageRoute(
                              builder: (_) => const MeuPerfilScreen(),
                            ),
                          )
                              .then((_) {
                            if (mounted && !_disposed) setState(() {});
                          });
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (_) => const MeuPerfilDialog(),
                        ).then((salvou) {
                          if (salvou == true && mounted && !_disposed) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Perfil atualizado com sucesso.'),
                                backgroundColor: GridColors.success,
                              ),
                            );
                          }
                        });
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: GridColors.primary,
                        child: _getUserAvatar().isNotEmpty
                            ? ClipOval(
                                child: Image.memory(
                                  _getUserAvatar(),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Text(
                                    _avatarInitial(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                _avatarInitial(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Nome do usuário + empresa/cliente
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getUserName().isNotEmpty
                                ? _getUserName()
                                : (AuthUtility.userInfo?.login?.email ?? ''),
                            style: const TextStyle(
                              color: GridColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                          ),
                          if (_getCompanyName().isNotEmpty)
                            Text(
                              _getCompanyName(),
                              style: TextStyle(
                                color: GridColors.textPrimary
                                    .withValues(alpha: 0.75),
                                fontSize: 11,
                                overflow: TextOverflow.ellipsis,
                              ),
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            ] else ...[
              Flexible(
                child: Text(
                  widget.screenTitle ?? "",
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        ...(widget.actions ?? const []),
        if (isLoggedIn) ...[
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                iconSize: 20,
                icon: const Icon(Icons.notifications,
                    color: GridColors.textPrimary),
                onPressed: () => showNotificationDropdown(context),
              ),
              if (unreadAlerts > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      unreadAlerts > 9 ? '9+' : '$unreadAlerts',
                      style: const TextStyle(
                        color: GridColors.textPrimary,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            iconSize: 20,
            icon: const Icon(Icons.logout, color: GridColors.textPrimary),
            onPressed: _handleLogout,
            tooltip: 'Sair',
          ),
        ]
      ],
      bottom: widget.customBottom ??
          ((widget.showFilterButton == true)
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(52),
                  child: FilterActionBar(
                    screenTitle: widget.screenTitle,
                    onRefresh: widget.onRefresh,
                    isLoading: widget.isLoading,
                    onFilterToggle: widget.onFilterToggle,
                    onColumns: widget.onColumns,
                  ),
                )
              : null),
    );
  }
}

// =============================================================================
// NOTIFICAÇÕES — tipos e painel redesenhado
// =============================================================================

class _NotificationTipoMeta {
  final IconData icone;
  final Color cor;
  final String rotulo;

  const _NotificationTipoMeta(this.icone, this.cor, this.rotulo);
}

/// Painel de notificações com visual tipo banco digital.
/// Funciona tanto como overlay (web/desktop) quanto embutido em bottom sheet (mobile).
class _NotificationPanel extends StatelessWidget {
  final List<Alert> notifications;
  final void Function(int id) onMarcarLida;
  final void Function(int id) onDeletar;
  final VoidCallback onMarcarTodas;
  final VoidCallback onFechar;
  final _NotificationTipoMeta Function(String status) resolverTipo;
  final String Function(String? data) dataRelativa;
  final ScrollController? scrollController;

  const _NotificationPanel({
    required this.notifications,
    required this.onMarcarLida,
    required this.onDeletar,
    required this.onMarcarTodas,
    required this.onFechar,
    required this.resolverTipo,
    required this.dataRelativa,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 520, minHeight: 180),
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GridColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCabecalho(context),
            if (notifications.isNotEmpty) _buildAcoes(),
            const Divider(height: 1, thickness: 1, color: GridColors.divider),
            Flexible(
              child: notifications.isNotEmpty ? _buildLista() : _buildVazio(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCabecalho(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      decoration: const BoxDecoration(
        color: GridColors.primary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: GridColors.textPrimary, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Notificações',
              style: TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (notifications.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${notifications.length}',
                style: const TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onFechar,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.close, color: GridColors.textPrimary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcoes() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            key: const Key('notificacoes_limpar_tudo_btn'),
            onPressed: onMarcarTodas,
            icon: const Icon(Icons.delete_sweep_outlined,
                size: 16, color: GridColors.error),
            label: const Text(
              'Limpar tudo',
              style: TextStyle(
                color: GridColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return ListView.builder(
      controller: scrollController,
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final n = notifications[index];
        final meta = resolverTipo(n.status);
        final dataStr = dataRelativa(n.data);
        // Primeiro item ou itens não lidos ficam com fundo levemente colorido
        final isNaoLido = n.status.toUpperCase() == 'NOVO' || index == 0;

        return InkWell(
          onTap: () => onMarcarLida(n.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isNaoLido
                  ? meta.cor.withValues(alpha: 0.06)
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                    color: GridColors.divider.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone colorido por tipo
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: meta.cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(meta.icone, color: meta.cor, size: 20),
                ),
                const SizedBox(width: 12),
                // Texto principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: meta.cor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              meta.rotulo,
                              style: TextStyle(
                                color: meta.cor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          if (isNaoLido) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: meta.cor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const Spacer(),
                          if (dataStr.isNotEmpty)
                            Text(
                              dataStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: GridColors.textMuted,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n.texto,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: GridColors.textSecondary,
                          fontWeight:
                              isNaoLido ? FontWeight.w600 : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Botão deletar
                InkWell(
                  onTap: () => onDeletar(n.id),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: GridColors.textMuted.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVazio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: GridColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_outlined,
              size: 36,
              color: GridColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tudo em dia!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nenhuma notificação pendente.',
            style: TextStyle(fontSize: 13, color: GridColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// APP BAR ACTIONS — notificação + logout reutilizáveis em qualquer AppBar
// =============================================================================

/// Ícones de notificação (com badge) e logout para adicionar em `actions` de
/// qualquer AppBar sem precisar usar UserBannerAppBar completo.
///
/// Uso: `actions: [const AppBarActions(), ...outrasActions]`
class AppBarActions extends StatefulWidget {
  const AppBarActions({super.key});

  @override
  State<AppBarActions> createState() => _AppBarActionsState();
}

class _AppBarActionsState extends State<AppBarActions> {
  List<Alert> _alerts = [];
  int _unreadCount = 0;
  Timer? _timer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
    _timer = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) _fetchAlerts();
    });
  }

  Future<void> _fetchAlerts() async {
    try {
      if (!AuthUtility.isLoggedIn) return;
      if (!mounted) return;
      final alerts = await AlertCaller().fetchNotificacoes(context);
      if (mounted && !_disposed) {
        setState(() {
          _alerts = alerts;
          _unreadCount = alerts.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _markRead(int id) async {
    Alert? alert;
    for (final a in _alerts) {
      if (a.id == id) {
        alert = a;
        break;
      }
    }
    if (alert != null) {
      await AlertCaller().marcarNotificacaoLida(alert);
    }
    if (mounted && !_disposed) {
      setState(() {
        _alerts.removeWhere((a) => a.id == id);
        _unreadCount = _alerts.length;
      });
    }
  }

  Future<void> _markAll() async {
    final sucesso = await AlertCaller().marcarTodasNotificacoesLidas();
    if (!sucesso) return;
    if (mounted && !_disposed) {
      setState(() {
        _alerts.clear();
        _unreadCount = 0;
      });
    }
  }

  String _dataRelativa(String? data) {
    if (data == null || data.isEmpty) return '';
    final d = DateTime.tryParse(data);
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    return DateFormat('dd/MM').format(d);
  }

  _NotificationTipoMeta _resolverTipo(String status) {
    final s = status.toUpperCase();
    if (s.contains('CHAMADO') || s.contains('TICKET'))
      return _NotificationTipoMeta(
          Icons.support_agent, GridColors.info, 'Chamado');
    if (s.contains('PAGAR') || s.contains('VENCIMENTO'))
      return _NotificationTipoMeta(
          Icons.payments_outlined, GridColors.error, 'A Pagar');
    if (s.contains('RECEBER'))
      return _NotificationTipoMeta(Icons.account_balance_wallet_outlined,
          GridColors.success, 'A Receber');
    if (s.contains('AVISO') || s.contains('COMUNICADO'))
      return _NotificationTipoMeta(
          Icons.campaign_outlined, GridColors.primaryLight, 'Aviso');
    return _NotificationTipoMeta(
        Icons.notifications_outlined, GridColors.primaryLight, 'Notificação');
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => _NotificationPanel(
          notifications: _alerts,
          onMarcarLida: _markRead,
          onDeletar: _markRead,
          onMarcarTodas: _markAll,
          onFechar: () => Navigator.pop(ctx),
          resolverTipo: _resolverTipo,
          dataRelativa: _dataRelativa,
          scrollController: scrollController,
        ),
      ),
    );
  }

  void _logout(BuildContext context) {
    AuthUtility.clearUserInfo();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AuthUtility.isLoggedIn) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              iconSize: 22,
              icon: const Icon(Icons.notifications,
                  color: GridColors.textPrimary),
              onPressed: () => _showNotifications(context),
              tooltip: 'Notificações',
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 14, minHeight: 14),
                  child: Text(
                    _unreadCount > 9 ? '9+' : '$_unreadCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          iconSize: 22,
          icon: const Icon(Icons.logout, color: GridColors.textPrimary),
          onPressed: () => _logout(context),
          tooltip: 'Sair',
        ),
      ],
    );
  }
}

// =============================================================================
// SIMPLE APP BAR — header padrão: ícone + título da tela + alertas + logout
// =============================================================================

/// AppBar único e consistente para telas standalone: à esquerda um ícone e o
/// nome da tela; à direita o sino de notificações (com badge) e o botão de
/// sair, via [AppBarActions]. Evita o "header duplo" e mantém o mesmo padrão
/// visual em todo o app.
class SimpleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData icon;

  /// Ações extras inseridas antes do sino/logout (ex.: refresh, upload).
  final List<Widget> extraActions;

  /// Barra inferior opcional (ex.: filtros, toggles de visualização).
  final PreferredSizeWidget? bottom;

  const SimpleAppBar({
    super.key,
    required this.title,
    this.icon = Icons.dashboard_rounded,
    this.extraActions = const [],
    this.bottom,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: GridColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: GridColors.textPrimary, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: GridColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        ...extraActions,
        const AppBarActions(),
        const SizedBox(width: 4),
      ],
      bottom: bottom,
    );
  }
}

// =============================================================================
// Nova barra de ações secundária
// =============================================================================
class FilterActionBar extends StatelessWidget {
  final String? screenTitle;
  final VoidCallback? onRefresh;
  final bool? isLoading;
  final VoidCallback? onFilterToggle;
  final VoidCallback? onColumns;

  const FilterActionBar({
    super.key,
    this.screenTitle,
    this.onRefresh,
    this.isLoading,
    this.onFilterToggle,
    this.onColumns,
  });

  @override
  Widget build(BuildContext context) {
    // Verde/nome-visivel APENAS no mobile nativo. Web/Windows mantem o visual
    // branco original (nao alterar fora do mobile).
    final bool isMobile = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final Color bg = isMobile ? GridColors.secondary : Colors.white;
    final Color fg = isMobile ? GridColors.textPrimary : GridColors.primary;

    return Container(
      height: 52,
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        color: bg,
        border: const Border(
          bottom: BorderSide(color: GridColors.divider, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Nome da tela antes dos botoes de acao
          Expanded(
            child: Text(
              screenTitle ?? "",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRefresh != null)
            IconButton(
              iconSize: 28,
              icon: isLoading ?? false
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Icon(Icons.refresh, color: fg),
              onPressed: isLoading ?? false ? null : onRefresh,
              tooltip: 'Recarregar dados',
            ),
          // Botao de personalizar grid: so quando ha grid (onColumns != null)
          if (onColumns != null)
            IconButton(
              iconSize: 28,
              icon: Icon(Icons.view_column, color: fg),
              onPressed: onColumns,
              tooltip: 'Configurar campos visíveis',
            ),
          // Botao de filtro: so quando ha grid/filtros (onFilterToggle != null)
          if (onFilterToggle != null)
            IconButton(
              iconSize: 28,
              icon: Icon(Icons.filter_list, color: fg),
              onPressed: onFilterToggle,
              tooltip: 'Mostrar/ocultar filtros',
            ),
        ],
      ),
    );
  }
}

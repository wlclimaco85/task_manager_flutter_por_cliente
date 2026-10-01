import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../models/chamado_model.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/grid_colors.dart';
import '../../../widgets/chat/chat_support_ui.dart';
import '../../../widgets/user_banners.dart';
import '../../services/chat_caller.dart';
import '../screens/chatMenssageScreen.dart';

class ChatListScreen extends StatefulWidget {
  final String userName;

  /// Fix (card #473): quando informado (ex.: navegação a partir da tela de
  /// detalhe do chamado), abre direto nesta conversa em vez da lista vazia,
  /// sem precisar passar pelo diálogo de seleção de setor.
  final String? initialChatId;
  final String? initialSector;

  const ChatListScreen({
    super.key,
    required this.userName,
    this.initialChatId,
    this.initialSector,
  });

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class Chat {
  final String chatId;
  final String sector;
  final String lastMessage;
  final DateTime timestamp;
  final String status;
  // Card #448 Fase 1: id do funcionario responsavel (codUsuDest do grupo).
  // Nulo = atendimento aguardando, ainda sem ninguem assumido.
  final int? responsavelId;

  Chat({
    required this.chatId,
    required this.sector,
    required this.lastMessage,
    required this.timestamp,
    required this.status,
    this.responsavelId,
  });
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<Chat> _chats = [];
  final List<Map<String, dynamic>> _setores = [];
  bool _isLoading = false;
  // Fix card #444: filtro Abertos/Finalizados (antes nao existia nenhum
  // filtro nem status real vindo do backend).
  bool _mostrarFinalizados = false;

  static const List<String> _fallbackSectors = [
    'Financeiro',
    'Departamento Pessoal',
    'Fiscal',
  ];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadSetores(), _loadChats()]);
      // Fix (card #473): se veio de navegação com uma conversa específica
      // (ex.: botão "Abrir Chat" na tela do chamado), abre direto a tela de
      // conversa em tela cheia (padrão mobile) -- não precisa existir na
      // lista ainda (pode ser a primeira mensagem).
      if (widget.initialChatId != null && mounted) {
        final existente = _chats.where((c) => c.chatId == widget.initialChatId);
        _openChat(existente.isNotEmpty
            ? existente.first
            : Chat(
                chatId: widget.initialChatId!,
                sector: widget.initialSector ?? 'Atendimento',
                lastMessage: '',
                timestamp: DateTime.now(),
                status: 'Ativo',
              ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadSetores() async {
    try {
      final itens = await Chamado.loadSetores();
      if (!mounted) return;
      setState(() {
        _setores
          ..clear()
          ..addAll(itens);
      });
    } catch (e) {
      _showSnack('Erro ao carregar setores: $e', error: true);
    }
  }

  Future<void> _loadChats() async {
    try {
      final data = await ChatCaller().fetchChats(context);
      final chats = data
          .map(
            (msg) => Chat(
              chatId: msg.chatId ?? '0',
              sector: msg.sector ?? 'Setor desconhecido',
              lastMessage: msg.text ?? msg.content,
              timestamp:
                  DateTime.tryParse(msg.uploadDate ?? msg.timestamp ?? '') ??
                      DateTime.now(),
              // Fix card #444: status real vindo do backend (agrupado por
              // chatId), antes hardcoded 'Ativo' para toda conversa.
              // Fix card #469: backend usa o enum FECHADO (nao "Finalizado")
              // para marcar conversa encerrada -- startsWith('final') nunca
              // batia com nenhum valor real, entao a conversa nunca saia de
              // "Abertos" mesmo apos finalizar com sucesso.
              status: (msg.status ?? '').toUpperCase() == 'FECHADO'
                  ? 'Finalizado'
                  : 'Ativo',
              responsavelId: msg.codUsuDest,
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _chats
          ..clear()
          ..addAll(chats);
      });
    } catch (e) {
      _showSnack('Erro ao carregar chats: $e', error: true);
    }
  }

  List<Chat> get _filteredChats => _chats
      .where((c) =>
          (c.status == 'Finalizado') == _mostrarFinalizados)
      .toList();

  List<String> get _sectorLabels {
    final labels = _setores
        .map((item) =>
            (item['label'] ?? item['descricao'] ?? item['nome'] ?? '')
                .toString())
        .where((label) => label.trim().isNotEmpty)
        .toList();
    return labels.isEmpty ? _fallbackSectors : labels;
  }

  void _startNewChat(String sector) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          sector: sector,
          userName: widget.userName,
          chatId: '0',
        ),
      ),
      // Fix card #444: ao voltar da conversa (ex.: apos finalizar), recarrega
      // a lista para refletir o status real.
    ).then((_) => _bootstrap());
  }

  Future<void> _showSectorSelectionDialog() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Novo atendimento',
                        style: TextStyle(
                          color: GridColors.textSecondary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _sectorLabels.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final sector = _sectorLabels[index];
                    return ListTile(
                      leading: const Icon(Icons.support_agent,
                          color: GridColors.primary),
                      title: Text(sector),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pop(context);
                        _startNewChat(sector);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChatActions(BuildContext context, Chat chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Visualizar'),
                onTap: () {
                  Navigator.pop(context);
                  _openChat(chat);
                },
              ),
              // Card #448 Fase 1: funcionario do setor pega o atendimento
              // aguardando (so quando ainda nao ha responsavel).
              if (chat.responsavelId == null)
                ListTile(
                  leading: const Icon(Icons.pan_tool_outlined, color: GridColors.primary),
                  title: const Text('Pegar atendimento'),
                  onTap: () {
                    Navigator.pop(context);
                    _pegarAtendimento(chat);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline,
                    color: GridColors.success),
                title: const Text('Finalizar'),
                onTap: () {
                  Navigator.pop(context);
                  _finalizeChat(chat);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: GridColors.error),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteChat(chat);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openChat(Chat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatMessageScreen(
          sector: chat.sector,
          userName: widget.userName,
          chatId: chat.chatId,
        ),
      ),
    ).then((_) => _bootstrap());
  }

  Future<void> _finalizeChat(Chat chat) async {
    if (chat.chatId.isEmpty || chat.chatId == '0') {
      _showSnack('Envie ao menos uma mensagem antes de finalizar.', error: true);
      return;
    }
    try {
      // Fix card #444: usava ApiLinks.chatFinalize (PUT /api/chat/{id} sem
      // corpo, id Integer de mensagem) -- mesmo bug ja corrigido no card
      // #430 dentro da tela de conversa, mas nao replicado aqui na lista.
      final url = TenantContext.applyToUrl(
          ApiLinks.chatFinalizarConversa(chat.chatId));
      final response = await http.put(Uri.parse(url), headers: TenantContext.headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          final index = _chats.indexWhere((item) => item.chatId == chat.chatId);
          if (index >= 0) {
            _chats[index] = Chat(
              chatId: chat.chatId,
              sector: chat.sector,
              lastMessage: chat.lastMessage,
              timestamp: chat.timestamp,
              status: 'Finalizado',
              responsavelId: chat.responsavelId,
            );
          }
        });
        _showSnack('Chat finalizado com sucesso');
      } else {
        _showSnack('Erro ao finalizar (${response.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao finalizar: $e', error: true);
    }
  }

  // Card #448 Fase 1: funcionario assume o atendimento aguardando.
  Future<void> _pegarAtendimento(Chat chat) async {
    final usuarioId = AuthUtility.userInfo?.login?.id;
    if (usuarioId == null) {
      _showSnack('Usuario nao identificado, faca login novamente.', error: true);
      return;
    }
    final ok = await ChatCaller().pegarAtendimento(chat.chatId, usuarioId);
    if (!mounted) return;
    if (ok) {
      _showSnack('Atendimento assumido com sucesso.');
      _bootstrap();
    } else {
      _showSnack('Atendimento ja possui responsavel ou ocorreu um erro.', error: true);
    }
  }

  Future<void> _deleteChat(Chat chat) async {
    try {
      final url = TenantContext.applyToUrl(ApiLinks.chatDelete(chat.chatId));
      final response = await http.delete(Uri.parse(url), headers: TenantContext.headers);
      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() => _chats.removeWhere((item) => item.chatId == chat.chatId));
        _showSnack('Chat excluído com sucesso');
      } else {
        _showSnack('Erro ao excluir (${response.statusCode})', error: true);
      }
    } catch (e) {
      _showSnack('Erro ao excluir: $e', error: true);
    }
  }

  void _showSnack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: error ? GridColors.error : GridColors.success,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatSupportPalette.page,
      appBar: UserBannerAppBar(
        screenTitle: 'Atendimento',
        onRefresh: _bootstrap,
        isLoading: _isLoading,
        showFilterButton: false,
      ),
      body: Column(
        children: [
          // Fix card #444: filtro Abertos/Finalizados (antes toda conversa
          // aparecia junta, sem forma de ver/reabrir uma ja finalizada).
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: _FiltroChip(
                    label: 'Abertos',
                    selected: !_mostrarFinalizados,
                    onTap: () => setState(() => _mostrarFinalizados = false),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FiltroChip(
                    label: 'Finalizados',
                    selected: _mostrarFinalizados,
                    onTap: () => setState(() => _mostrarFinalizados = true),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: GridColors.primary))
                : _filteredChats.isEmpty
                    ? ChatEmptyState(
                        title: _mostrarFinalizados
                            ? 'Nenhum chat finalizado'
                            : 'Nenhum chat iniciado',
                        message: _mostrarFinalizados
                            ? 'Conversas finalizadas aparecem aqui.'
                            : 'Abra um atendimento para falar com o setor responsavel.',
                        onStart:
                            _mostrarFinalizados ? null : _showSectorSelectionDialog,
                      )
                    : RefreshIndicator(
                        color: GridColors.primary,
                        onRefresh: _bootstrap,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(6, 10, 6, 88),
                          itemCount: _filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = _filteredChats[index];
                            final chamadoId = extrairChamadoIdDoChatId(chat.chatId);
                            return ChatListTileCard(
                              title: chamadoId != null
                                  ? 'Chamado #$chamadoId · ${chat.sector}'
                                  : chat.sector,
                              subtitle: chat.lastMessage,
                              time: DateFormat('HH:mm').format(chat.timestamp),
                              status: chat.status,
                              selected: false,
                              onTap: () => _openChat(chat),
                              onMore: () => _showChatActions(context, chat),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSectorSelectionDialog,
        tooltip: 'Novo atendimento',
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_comment_outlined),
      ),
    );
  }
}

/// Fix card #444: chip de filtro Abertos/Finalizados na lista de atendimento.
class _FiltroChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FiltroChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? GridColors.primary : GridColors.card,
          border: Border.all(
            color: selected ? GridColors.primary : GridColors.divider,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : GridColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

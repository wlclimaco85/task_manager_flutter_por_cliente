import 'dart:convert';
import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

// ── Cores do sistema ──────────────────────────────────────────────────────────
class _K {
  static const bg       = Color(0xFFF5F5F5);
  static const primary  = GridColors.primary;
  static const green    = GridColors.secondary;
  static const white    = Colors.white;
  static const border   = Color(0xFFDDDDDD);
  static const textDark = Color(0xFF212121);
  static const textGrey = Color(0xFF757575);
  static const sectorBg = Color(0xFFEEEEEE);
}

// ── Enum de status do chat ─────────────────────────────────────────────────────
enum StatusChat {
  PENDENTE(Color(0xFF1565C0), 'Pendente'),
  EM_ANDAMENTO(Color(0xFFE65100), 'Em Andamento'),
  FECHADO(GridColors.success, 'Fechado'),
  CANCELADO(Color(0xFF6A1B9A), 'Cancelado');

  final Color color;
  final String label;
  const StatusChat(this.color, this.label);

  static StatusChat? fromString(String? value) {
    if (value == null) return null;
    try {
      return StatusChat.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return StatusChat.PENDENTE;
    }
  }
}

// ── Modelo de Chat ─────────────────────────────────────────────────────────────
class ChatMsg {
  final int id;
  final int? empId;
  final int? codUsuOrig;
  final int? codUsuDest;
  final String? sector;
  final StatusChat status;
  final String? chatId;
  final DateTime? uploadDate;
  final String text;

  ChatMsg({
    required this.id,
    required this.empId,
    required this.codUsuOrig,
    required this.codUsuDest,
    required this.sector,
    required this.status,
    required this.chatId,
    required this.uploadDate,
    required this.text,
  });

  factory ChatMsg.fromJson(Map<String, dynamic> json) {
    return ChatMsg(
      id: json['id'] ?? 0,
      empId: json['empId'],
      codUsuOrig: json['codUsuOrig'],
      codUsuDest: json['codUsuDest'],
      sector: json['sector'],
      status: StatusChat.fromString(json['status']) ?? StatusChat.PENDENTE,
      chatId: json['chatId'],
      uploadDate: json['uploadDate'] != null
          ? DateTime.tryParse(json['uploadDate'].toString())
          : null,
      text: json['text'] ?? '(sem texto)',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class KanbanChatScreen extends StatefulWidget {
  const KanbanChatScreen({super.key});
  @override
  State<KanbanChatScreen> createState() => _KanbanChatScreenState();
}

class _KanbanChatScreenState extends State<KanbanChatScreen> {
  Map<String, Map<String, List<ChatMsg>>> _kanban = {};
  bool _loading = true;
  String? _erro;
  bool _movendo = false;
  final Set<String> _setoresColapsados = {};

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // Fix (card #475): endpoint GET /api/chat/kanban sempre retornou uma
  // lista PLANA de itens (GenericResponseDTO<List<ChatKanbanItemDTO>> ->
  // {"data": {"dados": [...], "totalElements": N}}), nunca o Map aninhado
  // (setor -> status -> lista) que esta tela sempre esperou. O parsing
  // antigo checava `data is Map` -- {dados, totalElements} É um Map, então
  // passava pelo `if`, mas tratava "dados"/"totalElements" como se fossem
  // nomes de setor, e o valor de "dados" (uma List) falhava no `is Map`
  // interno, então nenhum chat era agrupado -- o kanban sempre ficava
  // populado só com setores fantasma vazios, e a tela mostrava
  // "Nenhum chat encontrado". Corrigido para ler `data['dados']` como a
  // lista plana real e agrupar por setor/status aqui no frontend.
  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/api/chat/kanban');
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        final data = body['data'];
        final erroBackend = body['response']?['error'] == true;
        if (erroBackend) {
          setState(() => _erro =
              body['response']?['message'] ?? 'Erro ao carregar dados do kanban');
          return;
        }
        final List<dynamic> itens =
            (data is Map ? data['dados'] : null) ?? const [];

        final kanban = <String, Map<String, List<ChatMsg>>>{};
        for (final item in itens) {
          if (item is! Map) continue;
          try {
            final msg = ChatMsg.fromJson(Map<String, dynamic>.from(item));
            final setor = msg.sector?.trim().isNotEmpty == true
                ? msg.sector!
                : 'Sem setor';
            kanban.putIfAbsent(setor, () => {});
            kanban[setor]!.putIfAbsent(msg.status.name, () => []);
            kanban[setor]![msg.status.name]!.add(msg);
          } catch (_) {}
        }

        setState(() => _kanban = kanban);
      } else {
        setState(() => _erro = 'Erro ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _erro = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  List<String> get _setoresFiltrados {
    return _kanban.keys.toList()..sort();
  }

  List<ChatMsg> _porSetorEStatus(String setor, String status) {
    return _kanban[setor]?[status] ?? [];
  }

  Future<void> _moverChat(ChatMsg msg, String novoStatus) async {
    if (_movendo) return;
    setState(() => _movendo = true);

    try {
      final payload = <String, dynamic>{
        'id': msg.id,
        'text': msg.text,
        'status': novoStatus,
        'sector': msg.sector,
        'chatId': msg.chatId,
        'empId': msg.empId,
        if (msg.codUsuOrig != null) 'codUsuOrig': msg.codUsuOrig,
        if (msg.codUsuDest != null) 'codUsuDest': msg.codUsuDest,
      };

      final resp = await TenantContext.put(
        '${ApiLinks.baseUrl}/api/chat/${msg.id}',
        payload,
      );

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        await _carregar();
        if (mounted) {
          final novoStatusLabel =
              StatusChat.fromString(novoStatus)?.label ?? novoStatus;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat #${msg.id} movido para $novoStatusLabel'),
              backgroundColor: _K.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao mover: ${resp.statusCode}'),
              backgroundColor: _K.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: _K.primary,
          ),
        );
      }
    } finally {
      setState(() => _movendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _K.bg,
      appBar: AppBar(
        backgroundColor: _K.primary,
        foregroundColor: _K.white,
        elevation: 2,
        title: const Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 20),
            SizedBox(width: 8),
            Text(
              'Kanban — Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          if (_movendo)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            onPressed: _carregar,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_loading)
                LinearProgressIndicator(
                  color: _K.primary,
                  backgroundColor: _K.primary.withValues(alpha: 0.2),
                ),
              if (_erro != null)
                Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    _erro!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(child: _buildBoard()),
            ],
          ),
          if (_movendo)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _K.primary),
                        SizedBox(height: 12),
                        Text(
                          'Movendo chat...',
                          style: TextStyle(color: _K.textDark),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    final setores = _setoresFiltrados;

    if (setores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: _K.textGrey),
            const SizedBox(height: 12),
            const Text(
              'Nenhum chat disponível',
              style: TextStyle(color: _K.textGrey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final setor in setores)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_setoresColapsados.contains(setor)) {
                          _setoresColapsados.remove(setor);
                        } else {
                          _setoresColapsados.add(setor);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _K.sectorBg,
                        border: Border(
                          left: BorderSide(color: _K.primary, width: 4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _setoresColapsados.contains(setor)
                                ? Icons.expand_more
                                : Icons.expand_less,
                            size: 18,
                            color: _K.textDark,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              setor,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: _K.textDark,
                              ),
                            ),
                          ),
                          Text(
                            '${_kanban[setor]?.values.fold<int>(0, (a, b) => a + b.length) ?? 0} chats',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _K.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!_setoresColapsados.contains(setor)) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final status in StatusChat.values)
                            Container(
                              width: 300,
                              margin: const EdgeInsets.only(right: 12),
                              child: _buildStatusColumn(setor, status),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn(String setor, StatusChat status) {
    final chats = _porSetorEStatus(setor, status.name);
    final totalEmSetor =
        _kanban[setor]?.values.fold<int>(0, (a, b) => a + b.length) ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: _K.white,
        border: Border.all(color: _K.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: status.color, width: 2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status.color,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${chats.length}/$totalEmSetor',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _K.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: chats.isEmpty
                ? Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(8),
                    child: const Text(
                      'Vazio',
                      style: TextStyle(
                        color: _K.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  )
                : ReorderableListView(
                    padding: const EdgeInsets.all(4),
                    onReorder: (oldIndex, newIndex) {
                      // Reorderação visual apenas (não persiste)
                    },
                    children: [
                      for (final msg in chats)
                        Draggable<ChatMsg>(
                          key: ValueKey(msg.id),
                          data: msg,
                          feedback: Material(
                            elevation: 5,
                            child: _buildChatCard(msg, isDragging: true),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.5,
                            child: _buildChatCard(msg),
                          ),
                          child: _buildChatCard(msg),
                        ),
                    ],
                  ),
          ),
          // Zonas de drop para outros status
          for (final targetStatus in StatusChat.values
              .where((s) => s != status))
            DragTarget<ChatMsg>(
              onAccept: (msg) {
                _moverChat(msg, targetStatus.name);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  height: candidateData.isNotEmpty ? 40 : 0,
                  color: targetStatus.color.withValues(alpha: 0.2),
                  alignment: Alignment.center,
                  child: candidateData.isNotEmpty
                      ? Text(
                          'Soltar em ${targetStatus.label}',
                          style: TextStyle(
                            color: targetStatus.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        )
                      : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChatCard(ChatMsg msg, {bool isDragging = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      elevation: isDragging ? 4 : 0,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: isDragging ? _K.sectorBg : _K.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: msg.status.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '#${msg.id}',
                    style: const TextStyle(
                      color: _K.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (msg.uploadDate != null)
                  Text(
                    _formatDate(msg.uploadDate!),
                    style: const TextStyle(
                      fontSize: 9,
                      color: _K.textGrey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              msg.text.length > 80
                  ? '${msg.text.substring(0, 80)}...'
                  : msg.text,
              style: const TextStyle(
                fontSize: 11,
                color: _K.textDark,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.day}/${dt.month}/${dt.year % 100}';
  }
}

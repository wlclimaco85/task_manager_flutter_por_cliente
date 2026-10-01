import 'package:flutter/material.dart';
import 'dart:async';
import '../../services/instagram_service.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  List<TimelineEvent> _events = [];
  bool _loading = false;
  bool _snapshotting = false;
  String? _error;
  String? _lastSnapshotTime;
  String _currentUsername = '';
  bool _localApiStatus = false;

  @override
  void initState() {
    super.initState();
    _checkLocalApi();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _checkLocalApi() async {
    await InstagramService.checkLocalApi();
    if (mounted) setState(() => _localApiStatus = InstagramService.hasLocalApi);
  }

  Future<void> _search() async {
    final username = _controller.text.trim().replaceAll('@', '');
    if (username.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
      _currentUsername = username;
      _events = [];
    });

    await InstagramService.trackProfile(username);
    // fetchTimeline ja retorna todos os eventos, inclusive comentarios
    // (InstagramEvent com eventType "comment"); nao buscar em separado para
    // nao duplicar.
    final events = await InstagramService.fetchTimeline(username);

    final all = [...events];
    all.sort((a, b) {
      final da = a.dateTime ?? DateTime(2000);
      final db = b.dateTime ?? DateTime(2000);
      return db.compareTo(da);
    });

    if (mounted) {
      setState(() {
        _loading = false;
        _events = all;
        if (all.isEmpty) {
          _error = 'Nenhum evento encontrado.\nFaca um snapshot para comecar.';
        }
      });
    }
  }

  Future<void> _takeSnapshot() async {
    if (_currentUsername.isEmpty) return;

    setState(() => _snapshotting = true);

    final result = await InstagramService.takeSnapshot(_currentUsername);

    if (mounted) {
      setState(() => _snapshotting = false);
      if (result != null) {
        _lastSnapshotTime = DateTime.now().toString().substring(0, 19);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Snapshot salvo: ${result['followers']} seguidores, ${result['following']} seguindo'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        _search();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao tirar snapshot'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE1306C)))
                : _error != null
                    ? _buildError()
                    : _buildTimeline(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF833AB4), Color(0xFFE1306C), Color(0xFFF77737)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'TIMELINE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _localApiStatus ? Colors.green.withValues(alpha: 0.3) : Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: _localApiStatus ? Colors.greenAccent : Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      _localApiStatus ? 'API Local' : 'Indisponivel',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Acompanhe mudancas de seguidores, curtidas e comentarios',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onSubmitted: (_) => _search(),
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Perfil para monitorar',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFE1306C)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _snapshotting
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      ),
                    )
                  : GestureDetector(
                      onTap: _takeSnapshot,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white38),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                      ),
                    ),
            ],
          ),
          if (_currentUsername.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.white60, size: 14),
                const SizedBox(width: 4),
                Text(
                  'Monitorando: @$_currentUsername',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                if (_lastSnapshotTime != null) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.access_time, color: Colors.white60, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Ultimo snapshot: $_lastSnapshotTime',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.timeline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error!, style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          const Text('Como funciona:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          _buildInstruction(Icons.camera_alt, '1. Clique no botao de snapshot para salvar o estado atual'),
          _buildInstruction(Icons.hourglass_empty, '2. Aguarde e faca novos snapshots periodicamente'),
          _buildInstruction(Icons.timeline, '3. A timeline mostra as diferencas entre snapshots'),
          _buildInstruction(Icons.comment, '4. Comentarios sao coletados em tempo real'),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(height: 4),
                Text(
                  'Para snapshots, o servidor Python precisa estar rodando:\npython instagram_api/server.py --login',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstruction(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF833AB4)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Nenhum evento registrado', style: TextStyle(fontSize: 14, color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text(
              'Faca um snapshot para comecar a monitorar',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    final grouped = _groupByDay(_events);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final day = grouped.keys.elementAt(index);
        final dayEvents = grouped[day]!;
        return _buildDaySection(day, dayEvents);
      },
    );
  }

  Map<String, List<TimelineEvent>> _groupByDay(List<TimelineEvent> events) {
    final map = <String, List<TimelineEvent>>{};
    for (final e in events) {
      final dt = e.dateTime;
      String key;
      if (dt == null) {
        key = 'Sem data';
      } else {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final eventDay = DateTime(dt.year, dt.month, dt.day);
        final diff = today.difference(eventDay).inDays;
        if (diff == 0) key = 'Hoje';
        else if (diff == 1) key = 'Ontem';
        else if (diff < 7) key = 'Ha $diff dias';
        else key = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  Widget _buildDaySection(String day, List<TimelineEvent> events) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Color(0xFF833AB4), Color(0xFFE1306C)]),
                ),
              ),
              const SizedBox(width: 10),
              Text(day, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF262626))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1306C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${events.length}', style: const TextStyle(fontSize: 11, color: Color(0xFFE1306C), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        ...events.map((e) => _buildEventCard(e)),
        Container(
          margin: const EdgeInsets.only(left: 4),
          width: 2,
          height: 20,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildEventCard(TimelineEvent event) {
    final color = _eventColor(event.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(event.emoji, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '@${event.username}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF262626)),
                        ),
                      ),
                      Text(event.timeAgo, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                  if (event.fullName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(event.fullName, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.typeLabel,
                      style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (event.text != null && event.text!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        event.text!,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF262626), height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  if (event.postId != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.photo, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('Post #${event.postId}', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _eventColor(String type) {
    switch (type) {
      case 'new_follower': return const Color(0xFF4CAF50);
      case 'unfollowed': return const Color(0xFFF44336);
      case 'you_followed': return const Color(0xFF2196F3);
      case 'unfollowed_by_you': return const Color(0xFFFF9800);
      case 'liked_post': return const Color(0xFFE91E63);
      case 'unliked_post': return const Color(0xFF9C27B0);
      case 'comment': return const Color(0xFF00BCD4);
      default: return const Color(0xFF607D8B);
    }
  }
}

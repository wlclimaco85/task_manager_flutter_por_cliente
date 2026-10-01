import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

/// Tela de Gamificação — pontos, conquistas e ranking dos alunos (V003 Fase 6)
class GamificacaoScreen extends StatefulWidget {
  final int? alunoId;
  const GamificacaoScreen({super.key, this.alunoId});

  @override
  State<GamificacaoScreen> createState() => _GamificacaoScreenState();
}

class _GamificacaoScreenState extends State<GamificacaoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  bool _carregando = true;
  Map<String, dynamic>? _pontuacao;
  List<Map<String, dynamic>> _conquistas = [];
  List<Map<String, dynamic>> _ranking = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final alunoId = widget.alunoId ?? AuthUtility.userInfo?.data?.id;
    final token = AuthUtility.userInfo?.token;
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};
    setState(() => _carregando = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/gamificacao/pontuacao${alunoId != null ? '?alunoId=$alunoId' : ''}')),
            headers: headers),
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/gamificacao/conquistas${alunoId != null ? '?alunoId=$alunoId' : ''}')),
            headers: headers),
        http.get(Uri.parse(TenantContext.applyToUrl(
            '${ApiLinks.baseUrl}/api/gamificacao/ranking')), headers: headers),
      ]);
      if (!mounted) return;
      Map<String, dynamic>? pont;
      List<Map<String, dynamic>> conq = [], rank = [];
      if (results[0].statusCode == 200) {
        final b = jsonDecode(results[0].body);
        pont = Map<String, dynamic>.from(b['data'] ?? b);
      }
      if (results[1].statusCode == 200) {
        final b = jsonDecode(results[1].body);
        final lista = b['data'] ?? b['content'] ?? [];
        if (lista is List) conq = List<Map<String, dynamic>>.from(lista);
      }
      if (results[2].statusCode == 200) {
        final b = jsonDecode(results[2].body);
        final lista = b['data'] ?? b['content'] ?? [];
        if (lista is List) rank = List<Map<String, dynamic>>.from(lista);
      }
      setState(() {
        _pontuacao = pont;
        _conquistas = conq;
        _ranking = rank;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gamificação'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.star), text: 'Pontuação'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Conquistas'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
          ],
        ),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPontuacao(),
                _buildConquistas(),
                _buildRanking(),
              ],
            ),
    );
  }

  Widget _buildPontuacao() {
    final pontos = _pontuacao?['pontos'] ?? 0;
    final nivel = _pontuacao?['nivel'] ?? 1;
    final proximoNivel = _pontuacao?['pontosProximoNivel'] ?? 100;
    final progresso = pontos / (proximoNivel > 0 ? proximoNivel : 1);
    final streak = _pontuacao?['streakDias'] ?? 0;
    final totalTreinos = _pontuacao?['totalTreinos'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: GridColors.primary.withOpacity(0.1),
            border: Border.all(color: GridColors.primary, width: 3),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$pontos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: GridColors.primary)),
            Text('pontos', style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ),
        const SizedBox(height: 16),
        Text('Nível $nivel', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progresso.clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200, color: GridColors.primary,
            minHeight: 10),
        Text('$pontos / $proximoNivel pts para o próximo nível',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: _statCard('🔥 Streak', '$streak dias', Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _statCard('🏋️ Treinos', '$totalTreinos', GridColors.primary)),
        ]),
      ]),
    );
  }

  Widget _statCard(String label, String valor, Color cor) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: cor.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: cor.withOpacity(0.25)),
    ),
    child: Column(children: [
      Text(valor, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: cor)),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    ]),
  );

  Widget _buildConquistas() {
    if (_conquistas.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.emoji_events, size: 56, color: Colors.amber),
        SizedBox(height: 12),
        Text('Sem conquistas ainda — continue treinando!', style: TextStyle(color: Colors.grey)),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.2),
      itemCount: _conquistas.length,
      itemBuilder: (_, i) {
        final c = _conquistas[i];
        final desbloqueada = c['desbloqueada'] == true;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: desbloqueada ? Colors.amber.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: desbloqueada ? Colors.amber : Colors.grey.shade300),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(c['emoji']?.toString() ?? '🏅',
                style: TextStyle(fontSize: 32, color: desbloqueada ? null : Colors.grey)),
            const SizedBox(height: 6),
            Text(c['nome']?.toString() ?? '',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: desbloqueada ? Colors.black87 : Colors.grey),
                textAlign: TextAlign.center),
            Text(c['descricao']?.toString() ?? '',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
          ]),
        );
      },
    );
  }

  Widget _buildRanking() {
    if (_ranking.isEmpty) {
      return const Center(child: Text('Ranking não disponível', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: _ranking.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final r = _ranking[i];
        final pos = i + 1;
        final medalha = pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : '#$pos';
        return Card(
          child: ListTile(
            leading: Text(medalha, style: const TextStyle(fontSize: 22)),
            title: Text(r['nome']?.toString() ?? 'Aluno'),
            subtitle: Text('Nível ${r['nivel'] ?? 1}'),
            trailing: Text('${r['pontos'] ?? 0} pts',
                style: TextStyle(fontWeight: FontWeight.bold, color: GridColors.primary)),
          ),
        );
      },
    );
  }
}

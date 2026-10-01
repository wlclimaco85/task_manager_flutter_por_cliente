import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/auth_utility.dart';
import '../../../services/pdf_export_service.dart';
import '../../../utils/api_links.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/app_logger.dart';

/// Tela de histórico de sessões de treino de um aluno.
///
/// Recebe [alunoId] no construtor e busca as últimas 10 sessões via
/// GET /api/sessoes-treino/aluno/{alunoId}?limit=10.
class HistoricoTreinoScreen extends StatefulWidget {
  final int alunoId;

  const HistoricoTreinoScreen({
    super.key,
    required this.alunoId,
  });

  @override
  State<HistoricoTreinoScreen> createState() => _HistoricoTreinoScreenState();
}

class _HistoricoTreinoScreenState extends State<HistoricoTreinoScreen> {
  // Future cacheado para evitar rebuild loop no FutureBuilder
  late final Future<List<Map<String, dynamic>>> _futureSessoes;

  @override
  void initState() {
    super.initState();
    _futureSessoes = _buscarSessoes();
  }

  // ── Busca histórico no backend ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> _buscarSessoes() async {
    try {
      final url =
          '${ApiLinks.baseUrl}/api/sessoes-treino/aluno/${widget.alunoId}?limit=10';
      final resposta = await TenantContext.get(url);

      if (resposta.statusCode == 200) {
        final body = jsonDecode(resposta.body);
        final List raw = body is List
            ? body
            : (body is Map
                ? (body['data'] ??
                    body['content'] ??
                    body['items'] ??
                    body['dados'] ??
                    [])
                : []);
        return raw.whereType<Map>().map((e) {
          return Map<String, dynamic>.from(e);
        }).toList();
      }
      L.d('HistoricoTreino: HTTP ${resposta.statusCode}');
      return [];
    } catch (e) {
      L.d('Erro ao buscar histórico de treinos: $e');
      return [];
    }
  }

  // ── Formata duração em segundos para HH:MM:SS ou MM:SS ──────────────────────
  String _formatarDuracao(dynamic duracaoSegundos) {
    final total = (duracaoSegundos as num?)?.toInt() ?? 0;
    final horas = total ~/ 3600;
    final minutos = (total % 3600) ~/ 60;
    final segs = total % 60;
    final mm = minutos.toString().padLeft(2, '0');
    final ss = segs.toString().padLeft(2, '0');
    if (horas > 0) {
      return '${horas.toString().padLeft(2, '0')}:$mm:$ss';
    }
    return '$mm:$ss';
  }

  // ── Exporta PDF com o histórico de sessões ──────────────────────────────────
  Future<void> _exportarPdf() async {
    final sessoes = await _futureSessoes;
    final nomeAluno = AuthUtility.userInfo?.data?.codDadosPessoal?.nome ?? 'Aluno';
    final linhas = sessoes.map((s) {
      return [
        _formatarData(s['dataInicio'] ?? s['createdAt']),
        _formatarDuracao(s['duracaoSegundos']),
        '${(s['feedbackNota'] as num?)?.toInt() ?? 0}/5',
        s['feedbackTexto']?.toString() ?? '',
      ];
    }).toList();
    await PdfExportService.exportar(
      titulo: 'Histórico de Treinos — $nomeAluno',
      cabecalhos: const ['Data', 'Duração', 'Nota', 'Feedback'],
      linhas: linhas,
    );
  }

  // ── Exporta ficha de uma sessão específica ────────────────────────────────────
  Future<void> _exportarFichaSessao(dynamic sessaoId) async {
    try {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Gerando ficha...')));

      final url = '${ApiLinks.baseUrl}/api/sessoes-treino/$sessaoId/ficha-export';
      final resposta = await TenantContext.get(url);

      if (resposta.statusCode == 200) {
        final body = jsonDecode(resposta.body);
        final ficha = body is Map ? (body['data'] ?? body) : body;

        await PdfExportService.exportarFichaTreino(
          sessao: Map<String, dynamic>.from(ficha),
          series: (ficha['series'] as List?)
                  ?.map((s) => Map<String, dynamic>.from(s))
                  .toList() ??
              [],
        );
        ScaffoldMessenger.of(context).clearSnackBars();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: HTTP ${resposta.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
      L.d('Erro ao exportar ficha: $e');
    }
  }

  // ── Formata data ISO para DD/MM/YYYY HH:MM ──────────────────────────────────
  String _formatarData(dynamic dataIso) {
    if (dataIso == null) return '—';
    try {
      final dt = DateTime.parse(dataIso.toString()).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final m = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/${dt.year} $h:$min';
    } catch (_) {
      return dataIso.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.background,
      appBar: AppBar(
        title: const Text('Histórico de Treinos'),
        backgroundColor: GridColors.primary,
        foregroundColor: GridColors.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.description),
            tooltip: 'Exportar Ficha (última)',
            onPressed: () async {
              final sessoes = await _futureSessoes;
              if (sessoes.isNotEmpty) {
                _exportarFichaSessao(sessoes.first['id']);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nenhuma sessão disponível')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exportar Histórico PDF',
            onPressed: () => _exportarPdf(),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureSessoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: GridColors.error, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Erro ao carregar histórico.',
                    style: const TextStyle(color: GridColors.error),
                  ),
                ],
              ),
            );
          }

          final sessoes = snapshot.data ?? [];

          if (sessoes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fitness_center,
                      color: GridColors.neutral, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum treino registrado ainda',
                    style: TextStyle(
                      color: GridColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sessoes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              return _buildCardSessao(sessoes[index]);
            },
          );
        },
      ),
    );
  }

  // ── Card de uma sessão ───────────────────────────────────────────────────────
  Widget _buildCardSessao(Map<String, dynamic> sessao) {
    final nota = (sessao['feedbackNota'] as num?)?.toInt() ?? 0;
    final texto = sessao['feedbackTexto']?.toString();
    final duracao = _formatarDuracao(sessao['duracaoSegundos']);
    final data = _formatarData(sessao['dataInicio'] ?? sessao['createdAt']);

    return Card(
      color: GridColors.card,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: data e duração
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: GridColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      data,
                      style: const TextStyle(
                        color: GridColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined,
                        size: 16, color: GridColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      duracao,
                      style: const TextStyle(
                        color: GridColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Linha 2: estrelas
            Row(
              children: List.generate(5, (i) {
                return Icon(
                  (i + 1) <= nota ? Icons.star : Icons.star_border,
                  color: GridColors.warning,
                  size: 20,
                );
              }),
            ),
            // Linha 3: texto de feedback (se houver)
            if (texto != null && texto.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                texto,
                style: const TextStyle(
                  color: GridColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../trading_models.dart';
import '../trading_repository.dart';
import '../../../utils/grid_colors.dart';

class OportunidadesScreen extends StatefulWidget {
  const OportunidadesScreen({super.key});
  @override
  State<OportunidadesScreen> createState() => _OportunidadesScreenState();
}

class _OportunidadesScreenState extends State<OportunidadesScreen> {
  final _repo = TradingRepository();
  List<Opportunity> _oportunidades = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ops = await _repo.fetchOpportunities();
      // Ordena por scoreValue decrescente (ranking)
      ops.sort((a, b) => b.scoreValue.compareTo(a.scoreValue));
      if (mounted) setState(() => _oportunidades = ops);
    } catch (e) {
      if (mounted)
        setState(() => _error = 'Erro ao carregar oportunidades: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oportunidades — Ranking'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: GridColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: GridColors.error),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: GridColors.error)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : _oportunidades.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma oportunidade identificada',
                        style:
                            TextStyle(color: GridColors.divider, fontSize: 16),
                      ),
                    )
                  : RefreshIndicator(
                      color: GridColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _oportunidades.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _OportunidadeCard(
                            op: _oportunidades[i], rank: i + 1),
                      ),
                    ),
    );
  }
}

class _OportunidadeCard extends StatelessWidget {
  final Opportunity op;
  final int rank;
  const _OportunidadeCard({required this.op, required this.rank});

  Color _scoreCor(double score) {
    // scoreValue é 0–1 (BigDecimal) ou 0–100 — normaliza
    final normalizado = score > 1 ? score / 100.0 : score;
    if (normalizado >= 0.8) return GridColors.secondary; // verde
    if (normalizado >= 0.5) return GridColors.warning; // amarelo
    return GridColors.error; // vermelho
  }

  String _scoreLabel(double score) {
    final normalizado = score > 1 ? score / 100.0 : score;
    return '${(normalizado * 100).toStringAsFixed(0)}%';
  }

  Color _riskColor(String? riskLevel) {
    switch (riskLevel?.toUpperCase()) {
      case 'LOW':
      case 'BAIXO':
        return GridColors.secondary;
      case 'MEDIUM':
      case 'MEDIO':
      case 'MÉDIO':
        return GridColors.warning;
      case 'HIGH':
      case 'ALTO':
        return GridColors.error;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cor = _scoreCor(op.scoreValue);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: cor.withAlpha(80), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Posição no ranking
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: rank <= 3
                    ? GridColors.warning.withAlpha(40)
                    : Colors.grey.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: rank <= 3 ? GridColors.warning : Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Informações do ativo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Símbolo
                  Text(
                    op.assetSymbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: GridColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Recomendação
                  if (op.recommendation.isNotEmpty)
                    Text(
                      op.recommendation,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                  if (op.scoreResumo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      op.scoreResumo,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                  // Risk Level + Horizon
                  if (op.riskLevel != null || op.horizon != null)
                    Row(
                      children: [
                        if (op.riskLevel != null)
                          _Tag(
                            label: 'Risco: ${op.riskLevel}',
                            color: _riskColor(op.riskLevel),
                          ),
                        if (op.riskLevel != null && op.horizon != null)
                          const SizedBox(width: 6),
                        if (op.horizon != null)
                          _Tag(
                            label: op.horizon!,
                            color: Colors.blueGrey,
                          ),
                      ],
                    ),
                  // Data do cálculo
                  if (op.calculatedAt != null)
                    Text(
                      _formatDate(op.calculatedAt!),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                ],
              ),
            ),
            // Score badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cor.withAlpha(100)),
              ),
              child: Text(
                _scoreLabel(op.scoreValue),
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw;
    }
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

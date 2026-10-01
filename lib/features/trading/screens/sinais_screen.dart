import 'package:flutter/material.dart';
import '../trading_models.dart';
import '../trading_repository.dart';
import '../../../utils/grid_colors.dart';

class SinaisScreen extends StatefulWidget {
  const SinaisScreen({super.key});
  @override
  State<SinaisScreen> createState() => _SinaisScreenState();
}

class _SinaisScreenState extends State<SinaisScreen> {
  final _repo = TradingRepository();
  List<TradingSignal> _sinais = [];
  bool _loading = true;
  bool _analisando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _analisar() async {
    setState(() => _analisando = true);
    try {
      await _repo.analyzeWatchlist();
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao analisar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _analisando = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sinais = await _repo.fetchSignals();
      if (mounted) setState(() => _sinais = sinais);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro ao carregar sinais: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sinais de Mercado'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (_analisando)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.auto_graph),
              tooltip: 'Analisar watchlist agora',
              onPressed: _analisar,
            ),
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
                            style:
                                const TextStyle(color: GridColors.error)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load,
                          child: const Text('Tentar novamente')),
                    ],
                  ),
                )
              : _sinais.isEmpty
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.bar_chart, size: 64, color: GridColors.divider),
                        const SizedBox(height: 12),
                        const Text('Nenhum sinal gerado ainda',
                            style: TextStyle(color: GridColors.divider, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Adicione ativos à watchlist e clique em Analisar.',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _analisando ? null : _analisar,
                          style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
                          icon: const Icon(Icons.auto_graph, color: Colors.white),
                          label: const Text('Analisar Agora', style: TextStyle(color: Colors.white)),
                        ),
                      ]),
                    )
                  : RefreshIndicator(
                      color: GridColors.primary,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _sinais.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _SinalCard(sinal: _sinais[i]),
                      ),
                    ),
    );
  }
}

class _SinalCard extends StatelessWidget {
  final TradingSignal sinal;
  const _SinalCard({required this.sinal});

  Color get _corDirecao {
    final dir = sinal.displayDirection.toUpperCase();
    if (dir == 'BUY') return GridColors.secondary;
    if (dir == 'SELL') return GridColors.error;
    return Colors.grey;
  }

  String get _direcaoLabel => sinal.displayDirection.toUpperCase();

  String get _icone {
    final dir = sinal.displayDirection.toUpperCase();
    if (dir == 'BUY') return '▲';
    if (dir == 'SELL') return '▼';
    return '●';
  }

  @override
  Widget build(BuildContext context) {
    final preco = sinal.priceAtSignal > 0
        ? 'R\$ ${sinal.priceAtSignal.toStringAsFixed(2)}'
        : '—';
    final score = sinal.score > 0
        ? 'Score: ${(sinal.score * 100).toStringAsFixed(0)}%'
        : '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: _corDirecao.withAlpha(80), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Ícone de direção
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _corDirecao.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  _icone,
                  style: TextStyle(fontSize: 24, color: _corDirecao),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Símbolo + direção chip
                  Row(
                    children: [
                      Text(
                        sinal.assetSymbol,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: GridColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Chip(label: _direcaoLabel, color: _corDirecao),
                      if (sinal.status.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Chip(
                          label: sinal.status,
                          color: Colors.grey,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Preço de entrada
                  Text(
                    'Entrada: $preco',
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 13),
                  ),
                  // Score e timeframe
                  if (score.isNotEmpty || sinal.timeframe != null)
                    Text(
                      [score, if (sinal.timeframe != null) sinal.timeframe!]
                          .join('  '),
                      style: const TextStyle(
                          color: Colors.black54, fontSize: 12),
                    ),
                  // Data/hora
                  if (sinal.triggeredAt.isNotEmpty)
                    Text(
                      _formatDate(sinal.triggeredAt),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                ],
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

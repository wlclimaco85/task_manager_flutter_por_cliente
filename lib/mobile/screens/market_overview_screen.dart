import 'package:flutter/material.dart';

import '../../models/market_overview_model.dart';
import '../../models/order_model.dart';
import '../../services/market_caller.dart';
import '../../utils/grid_colors.dart';
import '../../widgets/market_overview_widgets.dart';

class MarketOverviewScreen extends StatefulWidget {
  /// Quando [showAppBar] é false, o AppBar interno é omitido.
  /// Útil para embutir a tela dentro de um TabBarView sem AppBar duplo.
  final bool showAppBar;

  const MarketOverviewScreen({super.key, this.showAppBar = true});

  @override
  State<MarketOverviewScreen> createState() => _MarketOverviewScreenState();
}

class _MarketOverviewScreenState extends State<MarketOverviewScreen> {
  MarketOverviewData? _market;
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      if (_market == null) {
        _loading = true;
      } else {
        _refreshing = refresh;
      }
      _error = null;
    });

    try {
      final market = await MarketCaller().fetchMarketOverview();
      if (!mounted) return;
      setState(() {
        _market = market;
        _loading = false;
        _refreshing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _refreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final market = _market;
    final hasContent = market?.hasContent ?? false;
    final assets = market?.monitoredAssets ?? const <MarketAssetSnapshot>[];

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: const Text('Mercado / Trading'),
              backgroundColor: GridColors.primary,
              foregroundColor: GridColors.textPrimary,
              actions: [
                if (_refreshing)
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  IconButton(
                    onPressed: () => _load(refresh: true),
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Atualizar',
                  ),
              ],
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_error != null && !hasContent)
              _ErrorPanel(error: _error!, onRetry: () => _load(refresh: true))
            else ...[
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _WarningPanel(
                    message:
                        'Última atualização falhou, exibindo dados anteriores. ${_error!}',
                    onRetry: () => _load(refresh: true),
                  ),
                ),
              _buildHeader(market),
              const SizedBox(height: 16),
              _buildSummarySection(market),
              const SizedBox(height: 16),
              _buildMonitoredAssetsSection(assets),
              const SizedBox(height: 16),
              _buildQuotesSection(market),
              const SizedBox(height: 16),
              _buildOrdersSection(
                title: 'Ordens em aberto',
                subtitle: 'Posições que ainda estão em execução',
                orders: market?.openOrders ?? const [],
              ),
              const SizedBox(height: 16),
              _buildOrdersSection(
                title: 'Ordens monitoradas',
                subtitle: 'Posições sob acompanhamento da estratégia',
                orders: market?.monitoredOrders ?? const [],
                highlightMonitored: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MarketOverviewData? market) {
    final lastUpdate = market?.updatedAt != null
        ? _formatDateTime(market!.updatedAt!)
        : 'Sem atualização recebida';
    final assetsCount = market?.monitoredAssets.length ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            GridColors.primary.withValues(alpha: 0.95),
            GridColors.secondary.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visão consolidada do mercado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ativos monitorados, últimas cotações e ordens em um único painel.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              Text(
                'Atualizado em $lastUpdate',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Text(
                '$assetsCount ativos monitorados',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(MarketOverviewData? market) {
    final metrics = market?.displaySummaryMetrics ?? const [];

    return MarketSectionCard(
      title: 'Resumo do mercado',
      subtitle: 'Indicadores consolidados da visão atual',
      child: metrics.isEmpty
          ? const MarketEmptyState(
              message: 'Nenhum resumo disponível para este mercado.',
            )
          : Wrap(
              spacing: 12,
              runSpacing: 12,
              children: metrics
                  .map(
                    (metric) => MarketMetricCard(
                      label: metric.label,
                      value: metric.value,
                      subtitle: metric.subtitle,
                      color: _colorForLabel(metric.label),
                      icon: _iconForLabel(metric.label),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildMonitoredAssetsSection(List<MarketAssetSnapshot> assets) {
    return MarketSectionCard(
      title: 'Ativos monitorados',
      subtitle: 'Últimos preços, variação, volume e data da coleta',
      child: MarketMonitoredAssetsList(assets: assets),
    );
  }

  Widget _buildQuotesSection(MarketOverviewData? market) {
    final quotes = market?.latestQuotes ?? const [];

    return MarketSectionCard(
      title: 'Últimas cotações',
      subtitle: 'Capturas recentes recebidas do backend',
      child: quotes.isEmpty
          ? const MarketEmptyState(
              message: 'Sem cotações recentes para exibir.',
              icon: Icons.show_chart,
            )
          : Column(
              children: [
                for (var i = 0; i < quotes.length; i++) ...[
                  MarketQuoteTile(quote: quotes[i]),
                  if (i < quotes.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }

  Widget _buildOrdersSection({
    required String title,
    required String subtitle,
    required List<OrderItem> orders,
    bool highlightMonitored = false,
  }) {
    return MarketSectionCard(
      title: title,
      subtitle: subtitle,
      child: orders.isEmpty
          ? MarketEmptyState(
              message: 'Sem itens em ${title.toLowerCase()}.',
              icon: highlightMonitored ? Icons.visibility_off : Icons.playlist_remove,
            )
          : Column(
              children: [
                for (var i = 0; i < orders.length; i++) ...[
                  MarketOrderTile(
                    order: orders[i],
                    highlightMonitored: highlightMonitored,
                  ),
                  if (i < orders.length - 1) const Divider(height: 1),
                ],
              ],
            ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorPanel({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Não foi possível carregar o mercado.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: const TextStyle(fontSize: 13, color: Colors.redAccent),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _WarningPanel extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _WarningPanel({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atualização parcial',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar atualizar novamente'),
          ),
        ],
      ),
    );
  }
}

Color _colorForLabel(String label) {
  final text = label.toLowerCase();
  if (text.contains('aberta') || text.contains('aberto')) return Colors.orange;
  if (text.contains('monitor')) return Colors.blue;
  if (text.contains('atualiza')) return Colors.teal;
  if (text.contains('lucro') || text.contains('alta') || text.contains('positivo')) {
    return Colors.green;
  }
  return GridColors.primary;
}

IconData _iconForLabel(String label) {
  final text = label.toLowerCase();
  if (text.contains('aberta') || text.contains('aberto')) return Icons.work_outline;
  if (text.contains('monitor')) return Icons.visibility;
  if (text.contains('atualiza')) return Icons.update;
  if (text.contains('ativo')) return Icons.monitor_heart_outlined;
  if (text.contains('lucro') || text.contains('alta') || text.contains('positivo')) {
    return Icons.trending_up;
  }
  return Icons.query_stats;
}

String _formatDateTime(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $hour:$minute';
}

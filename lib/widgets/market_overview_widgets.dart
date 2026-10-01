import 'package:flutter/material.dart';

import '../models/cotacao_model.dart';
import '../models/market_overview_model.dart';
import '../models/order_model.dart';
import '../utils/grid_colors.dart';

class MarketSectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const MarketSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: GridColors.primary.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: GridColors.textSecondary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: GridColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class MarketMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color color;
  final IconData icon;

  const MarketMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 260),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: GridColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: GridColors.textSecondary,
                      ),
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
}

class MarketMonitoredAssetsList extends StatelessWidget {
  final List<MarketAssetSnapshot> assets;

  const MarketMonitoredAssetsList({
    super.key,
    required this.assets,
  });

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return const MarketEmptyState(
        message: 'Nenhum ativo monitorado disponível no momento.',
        icon: Icons.monitor_heart_outlined,
      );
    }

    return Column(
      children: [
        for (var i = 0; i < assets.length; i++) ...[
          MarketAssetTile(asset: assets[i]),
          if (i < assets.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

class MarketAssetTile extends StatelessWidget {
  final MarketAssetSnapshot asset;

  const MarketAssetTile({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final variationColor = _variationColor(asset.variacao);
    final infoChips = <Widget>[
      _MiniInfo(label: 'Status', value: asset.acompanhamentoLabel),
      if (asset.status != null && asset.status!.trim().isNotEmpty)
        _MiniInfo(label: 'Ordem', value: asset.status),
      if (asset.openOrdersCount > 0)
        _MiniInfo(label: 'Abertas', value: asset.openOrdersCount.toString()),
      if (asset.monitoredOrdersCount > 0)
        _MiniInfo(label: 'Monitoradas', value: asset.monitoredOrdersCount.toString()),
      if (asset.origem != null && asset.origem!.trim().isNotEmpty)
        _MiniInfo(label: 'Origem', value: asset.origem),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: variationColor.withValues(alpha: 0.12),
            child: Icon(
              asset.variacao != null && asset.variacao! < 0
                  ? Icons.trending_down
                  : Icons.trending_up,
              color: variationColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            asset.ativo,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            asset.dataColeta != null
                                ? 'Coleta ${_formatDate(asset.dataColeta!)}'
                                : 'Sem data de coleta',
                            style: const TextStyle(
                              fontSize: 12,
                              color: GridColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _money(asset.preco),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: GridColors.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _percent(asset.variacao),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: variationColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: infoChips,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _ValueInfo(label: 'Preço', value: _money(asset.preco)),
                    _ValueInfo(
                      label: 'Variação',
                      value: _percent(asset.variacao),
                      valueColor: variationColor,
                    ),
                    _ValueInfo(label: 'Volume', value: _volume(asset.volume)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MarketQuoteTile extends StatelessWidget {
  final Cotacao quote;

  const MarketQuoteTile({super.key, required this.quote});

  @override
  Widget build(BuildContext context) {
    final updatedAt = quote.dataColeta ?? quote.dtCotacao;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: GridColors.primary.withValues(alpha: 0.12),
        child: const Icon(Icons.trending_up, color: GridColors.primary),
      ),
      title: Text(
        quote.ativo ?? 'Ativo',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            updatedAt != null ? _formatDate(updatedAt) : 'Sem data',
            style: const TextStyle(fontSize: 12),
          ),
          if (quote.volume != null || quote.variacaoPercentual != null)
            Text(
              'Variação ${_percent(quote.variacaoPercentual)} • Volume ${_volume(quote.volume)}',
              style: const TextStyle(
                fontSize: 11,
                color: GridColors.textSecondary,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money(quote.preco ?? quote.valor),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: GridColors.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            quote.origem ?? 'Última cotação',
            style: const TextStyle(fontSize: 11, color: GridColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class MarketOrderTile extends StatelessWidget {
  final OrderItem order;
  final bool highlightMonitored;

  const MarketOrderTile({
    super.key,
    required this.order,
    this.highlightMonitored = false,
  });

  @override
  Widget build(BuildContext context) {
    final lucro = order.lucro;
    final lucroText = lucro == null ? '—' : 'R\$ ${lucro.toStringAsFixed(2)}';
    final lucroColor =
        lucro == null ? GridColors.textSecondary : (lucro >= 0 ? Colors.green : Colors.red);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: highlightMonitored
                ? Colors.blue.withValues(alpha: 0.12)
                : GridColors.primary.withValues(alpha: 0.12),
            child: Icon(
              highlightMonitored ? Icons.visibility : Icons.swap_horiz,
              color: highlightMonitored ? Colors.blue : GridColors.primary,
              size: 18,
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
                        order.acao ?? 'Ativo não informado',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _StatusChip(label: order.status ?? 'Sem status'),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MiniInfo(label: 'Tipo', value: order.tipo),
                    _MiniInfo(label: 'Estratégia', value: order.estrategia),
                    _MiniInfo(label: 'Ambiente', value: order.ambiente),
                    _MiniInfo(label: 'Robô', value: order.nomeRobo),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    _ValueInfo(label: 'Compra', value: _money(order.valorCompra)),
                    _ValueInfo(label: 'Atual', value: _money(order.cotacaoAtual)),
                    _ValueInfo(
                      label: 'Lucro',
                      value: lucroText,
                      valueColor: lucroColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MarketEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const MarketEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: GridColors.textSecondary.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: GridColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String label;
  final String? value;

  const _MiniInfo({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: ${value ?? '—'}'),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(fontSize: 11),
      backgroundColor: Colors.grey.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}

class _ValueInfo extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ValueInfo({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12, color: GridColors.textSecondary),
        children: [
          TextSpan(text: '$label: '),
          TextSpan(
            text: value,
            style: TextStyle(
              color: valueColor ?? GridColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;

  const _StatusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: GridColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: GridColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

String _money(double? value) {
  if (value == null) return '—';
  return 'R\$ ${value.toStringAsFixed(2)}';
}

String _percent(double? value) {
  if (value == null) return '—';
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}%';
}

String _volume(double? value) {
  if (value == null) return '—';
  if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(2)} bi';
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)} mi';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)} mil';
  return value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
}

Color _variationColor(double? value) {
  if (value == null) return GridColors.primary;
  if (value < 0) return Colors.red;
  if (value > 0) return Colors.green;
  return Colors.orange;
}

String _formatDate(DateTime dateTime) {
  final day = dateTime.day.toString().padLeft(2, '0');
  final month = dateTime.month.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$day/$month/${dateTime.year} $hour:$minute';
}

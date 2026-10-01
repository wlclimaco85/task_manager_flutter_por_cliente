import 'package:flutter/material.dart';
import '../../models/kpi_dashboard_model.dart';

/// Card de KPI genérico reaproveitado pelos 5 dashboards de área (Fase 171).
/// Fica clicável SOMENTE quando [onTap] != null E [kpi.drillDownRota] != null
/// (contrato de drill-down fixado na Onda 0 — nunca crash silencioso por rota
/// não resolvida).
class KpiCard extends StatelessWidget {
  final KpiDashboardModel kpi;
  final DateTime? periodoInicio;
  final DateTime? periodoFim;

  /// Drill-down tipado — NÃO é VoidCallback. Quem instancia o KpiCard repassa
  /// o período atualmente selecionado no DashboardAreaScaffold.
  final void Function(
    DateTime? periodoInicio,
    DateTime? periodoFim,
    String? drillDownRota,
  )? onTap;

  const KpiCard({
    super.key,
    required this.kpi,
    this.periodoInicio,
    this.periodoFim,
    this.onTap,
  });

  bool get _clicavel => onTap != null && kpi.drillDownRota != null;

  IconData? get _iconeTendencia {
    switch (kpi.tendencia) {
      case 'ALTA':
        return Icons.trending_up;
      case 'BAIXA':
        return Icons.trending_down;
      case 'ESTAVEL':
        return Icons.trending_flat;
      default:
        return null;
    }
  }

  Color? _corTendencia(BuildContext context) {
    switch (kpi.tendencia) {
      case 'ALTA':
        return Colors.green;
      case 'BAIXA':
        return Colors.red;
      case 'ESTAVEL':
        return Colors.grey;
      default:
        return null;
    }
  }

  String get _valorFormatado {
    final unidade = kpi.unidade;
    final valorStr = kpi.valor.toStringAsFixed(
      kpi.valor.truncateToDouble() == kpi.valor ? 0 : 2,
    );
    if (unidade == null) return valorStr;
    if (unidade == 'R\$') return '$unidade $valorStr';
    return '$valorStr $unidade';
  }

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              kpi.label,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _valorFormatado,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_iconeTendencia != null)
                  Icon(_iconeTendencia, color: _corTendencia(context), size: 20),
              ],
            ),
          ],
        ),
      ),
    );

    if (!_clicavel) return card;

    return InkWell(
      onTap: () => onTap!(periodoInicio, periodoFim, kpi.drillDownRota),
      child: card,
    );
  }
}

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/dashboard_model.dart';
import '../../utils/grid_colors.dart';

class FinanceFluxoDiarioChart extends StatelessWidget {
  FinanceFluxoDiarioChart({
    super.key,
    required this.data,
  });

  final List<FinanceFluxoPoint> data;
  final NumberFormat _compactCurrency =
      NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');

  String _ddMM(DateTime d) => DateFormat('dd/MM').format(d);

  double _resolveMaxY() {
    var maxValue = 0.0;
    for (final item in data) {
      maxValue = math.max(maxValue, item.receivable.abs());
      maxValue = math.max(maxValue, item.payable.abs());
      maxValue = math.max(maxValue, item.net.abs());
    }

    if (maxValue <= 0) return 100;
    return (maxValue * 1.2).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 280,
        child: Center(child: Text('Sem dados de fluxo de caixa no período.')),
      );
    }

    final maxY = _resolveMaxY();
    final labelStep = data.length > 20 ? 5 : data.length > 12 ? 3 : 1;

    return Container(
      height: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _LegendChip(color: Colors.green, label: 'Entradas'),
              _LegendChip(color: Colors.red, label: 'Saídas'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFE9EEF5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxY / 4,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          _compactCurrency.format(value),
                          style: const TextStyle(
                            fontSize: 10,
                            color: GridColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        final isEdge =
                            index == 0 || index == data.length - 1;
                        if (!isEdge && index % labelStep != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _ddMM(data[index].day),
                            style: const TextStyle(
                              fontSize: 10,
                              color: GridColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < data.length; i++)
                    BarChartGroupData(
                      x: i,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: data[i].receivable,
                          color: Colors.green,
                          width: 7,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: data[i].payable,
                          color: Colors.red,
                          width: 7,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: GridColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

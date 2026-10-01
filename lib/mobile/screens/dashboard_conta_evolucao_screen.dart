import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/conta_model.dart';
import '../../services/conta_caller.dart';
import '../../utils/grid_colors.dart';

class ContaEvolucaoChart extends StatefulWidget {
  const ContaEvolucaoChart({
    super.key,
    required this.conta,
    this.days = 30,
  });

  final ContaBancariaModel conta;
  final int days;

  @override
  State<ContaEvolucaoChart> createState() => _ContaEvolucaoChartState();
}

class _ContaEvolucaoChartState extends State<ContaEvolucaoChart> {
  final NumberFormat _currency =
      NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');

  List<ContaSaldoDia> serie = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await ContaApi().evolucao(
        contaId: widget.conta.id,
        days: widget.days,
      );
      if (!mounted) return;
      setState(() {
        serie = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 260,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return SizedBox(
        height: 260,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }
    if (serie.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Sem histórico de saldo para esta conta.')),
      );
    }

    final minY = serie
        .map((e) => e.saldo)
        .reduce(math.min);
    final maxY = serie
        .map((e) => e.saldo)
        .reduce(math.max);
    final padding = math.max(((maxY - minY).abs()) * 0.15, 50.0);
    final interval = math.max(((maxY - minY).abs() + padding * 2) / 4, 1.0);
    final labelStep = serie.length > 20 ? 5 : serie.length > 12 ? 3 : 1;

    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.conta.nome,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY - padding,
                maxY: maxY + padding,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: Color(0xFFE9EEF5),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: interval,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          _currency.format(value),
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
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index < 0 || index >= serie.length) {
                          return const SizedBox.shrink();
                        }
                        final isEdge = index == 0 || index == serie.length - 1;
                        if (!isEdge && index % labelStep != 0) {
                          return const SizedBox.shrink();
                        }
                        final date = serie[index].day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('dd/MM').format(date),
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
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: GridColors.secondary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    spots: [
                      for (int i = 0; i < serie.length; i++)
                        FlSpot(i.toDouble(), serie[i].saldo),
                    ],
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          GridColors.secondary.withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
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

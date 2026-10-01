import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/cotacao_model.dart';

class CotacaoChart extends StatelessWidget {
  final List<Cotacao> cotacoes;

  const CotacaoChart({super.key, required this.cotacoes});

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < cotacoes.length) {
                  return Text(
                    '${cotacoes[index].dtCotacao?.day}/${cotacoes[index].dtCotacao?.month}',
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.blue, width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: cotacoes.asMap().entries.map((entry) {
              int index = entry.key;
              Cotacao cotacao = entry.value;
              return FlSpot(index.toDouble(), cotacao.valor ?? 0);
            }).toList(),
            isCurved: true,
            color: Colors.blue, // Atualização da cor
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        gridData: const FlGridData(show: false),
      ),
    );
  }
}

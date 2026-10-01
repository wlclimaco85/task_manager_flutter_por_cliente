import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../models/cotacao_model.dart';
import 'package:intl/intl.dart';

class CotacaoChart extends StatefulWidget {
  final List<Cotacao> cotacoes;

  const CotacaoChart({super.key, required this.cotacoes});

  @override
  _CotacaoChartState createState() => _CotacaoChartState();
}

class _CotacaoChartState extends State<CotacaoChart> {
  String filtroSelecionado =
      'Último mês'; // Filtro inicial definido como "Último mês"
  List<Cotacao> cotacoesFiltradas = [];

  @override
  void initState() {
    super.initState();
    filtrarCotacoes(); // Aplica o filtro ao carregar o widget
  }

  void filtrarCotacoes() {
    final agora = DateTime.now();

    setState(() {
      if (filtroSelecionado == 'Última semana') {
        cotacoesFiltradas = widget.cotacoes
            .where((c) =>
                c.dtCotacao != null &&
                c.dtCotacao!.isAfter(agora.subtract(const Duration(days: 7))))
            .toList();
      } else if (filtroSelecionado == 'Último mês') {
        cotacoesFiltradas = widget.cotacoes
            .where((c) =>
                c.dtCotacao != null &&
                c.dtCotacao!
                    .isAfter(DateTime(agora.year, agora.month - 1, agora.day)))
            .toList();
      } else if (filtroSelecionado == 'Último ano') {
        cotacoesFiltradas = widget.cotacoes
            .where((c) =>
                c.dtCotacao != null &&
                c.dtCotacao!
                    .isAfter(DateTime(agora.year - 1, agora.month, agora.day)))
            .toList();
      } else {
        cotacoesFiltradas = widget.cotacoes
            .where((c) =>
                c.dtCotacao != null &&
                c.dtCotacao!
                    .isAfter(DateTime(agora.year, agora.month - 1, agora.day)))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < cotacoesFiltradas.length) {
                        final data = cotacoesFiltradas[index].dtCotacao;
                        if (data != null) {
                          return Text(
                            DateFormat('dd/MM').format(data),
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.blue, width: 1),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: cotacoesFiltradas.asMap().entries.map((entry) {
                    int index = entry.key;
                    Cotacao cotacao = entry.value;
                    return FlSpot(index.toDouble(), cotacao.valor ?? 0);
                  }).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              minX: 0,
              maxX: cotacoesFiltradas.length.toDouble() - 1,
              minY: 0,
              maxY: cotacoesFiltradas
                  .map((c) => c.valor ?? 0)
                  .fold(0, (a, b) => a! > b ? a : b),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  filtroSelecionado = 'Última semana';
                  filtrarCotacoes();
                });
              },
              child: const Text('Última semana'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  filtroSelecionado = 'Último mês';
                  filtrarCotacoes();
                });
              },
              child: const Text('Último mês'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  filtroSelecionado = 'Último ano';
                  filtrarCotacoes();
                });
              },
              child: const Text('Último ano'),
            ),
          ],
        ),
      ],
    );
  }
}

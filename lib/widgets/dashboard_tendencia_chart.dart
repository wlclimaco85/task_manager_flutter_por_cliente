import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mes_cobranca_model.dart';
import '../utils/grid_colors.dart';

/// Widget que exibe gráfico de linha da tendência de cobrança (6 meses).
/// Mostra evolução de quantidade de mensalidades e valor total por mês.
class DashboardTendenciaChart extends StatelessWidget {
  final List<MesCobranca> dados;
  final String titulo;

  const DashboardTendenciaChart({
    super.key,
    required this.dados,
    this.titulo = 'Tendência de Cobrança (6 Meses)',
  });

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Center(child: Text('Nenhum dado disponível')),
            ],
          ),
        ),
      );
    }

    // Ordena dados por mês (ascendente)
    final dadosOrdenados = List<MesCobranca>.from(dados)
      ..sort((a, b) => a.mes.compareTo(b.mes));

    final maxValor = (dadosOrdenados.fold<double>(
            0.0, (max, item) => item.valor > max ? item.valor : max) *
        1.1);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < dadosOrdenados.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                _formatarMes(dadosOrdenados[index].mes),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 40,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatarValor(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 60,
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (dadosOrdenados.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxValor,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List<FlSpot>.generate(
                        dadosOrdenados.length,
                        (index) => FlSpot(
                          index.toDouble(),
                          dadosOrdenados[index].valor,
                        ),
                      ),
                      isCurved: true,
                      color: GridColors.primary,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: GridColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Resumo em tabela
            _buildResumoTabela(dadosOrdenados),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoTabela(List<MesCobranca> dados) {
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Mês')),
          DataColumn(label: Text('Qtd.')),
          DataColumn(label: Text('Valor')),
        ],
        rows: dados.map((item) {
          return DataRow(cells: [
            DataCell(Text(_formatarMes(item.mes))),
            DataCell(Text('${item.quantidade}')),
            DataCell(Text(nf.format(item.valor))),
          ]);
        }).toList(),
      ),
    );
  }

  String _formatarMes(String mesStr) {
    // "2026-01" → "Jan/26"
    try {
      final partes = mesStr.split('-');
      if (partes.length == 2) {
        final ano = partes[0];
        final mes = int.parse(partes[1]);
        final nomes = [
          'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
          'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
        ];
        return '${nomes[mes - 1]}/${ano.substring(2)}';
      }
    } catch (e) {
      debugPrint('Erro ao formatar mês: $e');
    }
    return mesStr;
  }

  String _formatarValor(double valor) {
    if (valor >= 1000000) return '${(valor / 1000000).toStringAsFixed(1)}M';
    if (valor >= 1000) return '${(valor / 1000).toStringAsFixed(1)}K';
    return valor.toStringAsFixed(0);
  }
}

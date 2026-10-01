// lib/dashboard/dashboard_page.dart
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../models/auth_utility.dart';
import '../../../utils/grid_colors.dart';
import '../../../utils/api_links.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class TicketTrendPoint {
  final String month; // YYYY-MM
  final int open;
  final int inProgress;
  final int closed;

  TicketTrendPoint({
    required this.month,
    required this.open,
    required this.inProgress,
    required this.closed,
  });

  factory TicketTrendPoint.fromJson(Map<String, dynamic> j) {
    return TicketTrendPoint(
      month: j['month'],
      open: (j['openCount'] ?? 0) as int,
      inProgress: (j['inProgressCount'] ?? 0) as int,
      closed: (j['closedCount'] ?? 0) as int,
    );
  }
}

class TicketsTrendChart extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int months;

  const TicketsTrendChart({
    super.key,
    required this.empresaId,
    this.parceiroId,
    this.months = 6,
  });

  @override
  State<TicketsTrendChart> createState() => _TicketsTrendChartState();
}

class _TicketsTrendChartState extends State<TicketsTrendChart> {
  List<TicketTrendPoint> data = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse(ApiLinks.ticketsTrend).replace(queryParameters: {
        'months': widget.months.toString(),
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
      });

      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Important: Add Accept header
        },
      );
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');
      final arr = jsonDecode(res.body) as List;

      setState(() {
        data = arr.map((e) => TicketTrendPoint.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  String _mm(String ym) => ym.length >= 7 ? ym.substring(5, 7) : ym;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
          height: 260, child: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return SizedBox(
        height: 260,
        child: Center(
            child:
                Text(error!, style: const TextStyle(color: Colors.redAccent))),
      );
    }
    if (data.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Sem dados de tendência de chamados.')),
      );
    }

    final openSpots = <FlSpot>[];
    final progSpots = <FlSpot>[];
    final closedSpots = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      openSpots.add(FlSpot(i.toDouble(), data[i].open.toDouble()));
      progSpots.add(FlSpot(i.toDouble(), data[i].inProgress.toDouble()));
      closedSpots.add(FlSpot(i.toDouble(), data[i].closed.toDouble()));
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // legend
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.orange, label: 'Abertos'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.blue, label: 'Andamento'),
              SizedBox(width: 12),
              _LegendDot(color: Colors.green, label: 'Fechados'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touched) =>
                        GridColors.primary.withValues(alpha: 0.85),
                    getTooltipItems: (spots) {
                      return spots.map((s) {
                        final i = s.spotIndex;
                        final m = data[i].month;
                        final val = s.y.toInt();
                        return LineTooltipItem(
                          'Mês ${_mm(m)}\n$val chamados',
                          const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _mm(data[i].month),
                            style: const TextStyle(
                                fontSize: 10, color: GridColors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    spots: openSpots,
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    spots: progSpots,
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    spots: closedSpots,
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: GridColors.textSecondary)),
      ],
    );
  }
}

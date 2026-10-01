import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/grid_colors.dart';
import '../../../utils/api_links.dart';
import '../../../models/auth_utility.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class ChatDailyPoint {
  final DateTime date;
  final int count;
  ChatDailyPoint(this.date, this.count);

  factory ChatDailyPoint.fromJson(Map<String, dynamic> j) {
    final rawCount = j['count'];
    final int count;
    if (rawCount == null) {
      count = 0;
    } else if (rawCount is int) {
      count = rawCount;
    } else if (rawCount is num) {
      count = rawCount.toInt();
    } else {
      count = int.tryParse(rawCount.toString()) ?? 0;
    }
    return ChatDailyPoint(DateTime.parse(j['date']), count);
  }
}

class ChatsDailyChart extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int days;

  const ChatsDailyChart({
    super.key,
    required this.empresaId,
    this.parceiroId,
    this.days = 7,
  });

  @override
  State<ChatsDailyChart> createState() => _ChatsDailyChartState();
}

class _ChatsDailyChartState extends State<ChatsDailyChart> {
  List<ChatDailyPoint> data = [];
  bool loading = true;
  String? error;
  bool animateIn = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse(ApiLinks.chatDailys).replace(queryParameters: {
        'days': widget.days.toString(),
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
        data = arr.map((e) => ChatDailyPoint.fromJson(e)).toList();
        loading = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => animateIn = true);
      });
    } catch (e) {
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
          child: Text(
            error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
          ),
        ),
      );
    }

    if (data.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(
          child: Text(
            'Nenhum dado de chat nos últimos dias.',
            style: TextStyle(color: GridColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    final spots = [
      for (int i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].count.toDouble()),
    ];

    return AnimatedOpacity(
      opacity: animateIn ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      child: Container(
        height: 260,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: GridColors.primary.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (LineBarSpot touchedSpot) {
                  return GridColors.primary.withValues(alpha: 0.85);
                },
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final d = data[spot.spotIndex].date;
                    return LineTooltipItem(
                      '${d.day}/${d.month}\n${spot.y.toInt()} mensagens',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 26,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final d = data[i].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${d.day}/${d.month}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: GridColors.textSecondary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: GridColors.secondary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      GridColors.secondary.withValues(alpha: 0.35),
                      Colors.transparent
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                spots: spots,
              )
            ],
            minY: 0,
          ),
        ),
      ),
    );
  }
}

// lib/dashboard/dashboard_page.dart
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/grid_colors.dart';
import '../../../utils/api_links.dart';
import '../../../models/auth_utility.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class FinanceTrendPoint {
  final String month; // '2025-07'
  final double receivable;
  final double payable;
  FinanceTrendPoint(this.month, this.receivable, this.payable);

  factory FinanceTrendPoint.fromJson(Map<String, dynamic> j) =>
      FinanceTrendPoint(j['month'], (j['receivable'] as num).toDouble(),
          (j['payable'] as num).toDouble());
}

class FinanceTrendChart extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int months;
  const FinanceTrendChart({
    super.key,
    required this.empresaId,
    this.parceiroId,
    this.months = 6,
  });

  @override
  State<FinanceTrendChart> createState() => _FinanceTrendChartState();
}

class _FinanceTrendChartState extends State<FinanceTrendChart> {
  List<FinanceTrendPoint> data = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse(ApiLinks.trend).replace(queryParameters: {
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
        data = arr.map((e) => FinanceTrendPoint.fromJson(e)).toList();
        loading = false;
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
          height: 220, child: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return SizedBox(
          height: 220,
          child: Center(
              child: Text(error!, style: const TextStyle(color: Colors.red))));
    }
    if (data.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Sem dados de tendencia financeira.')),
      );
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final m = data[i].month;
                  final label = m.length >= 7 ? m.substring(5, 7) : m;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 10, color: GridColors.textSecondary)),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.green,
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].receivable)
              ],
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    Colors.green.withValues(alpha: .3),
                    Colors.transparent
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              isCurved: true,
              color: Colors.red,
              spots: [
                for (int i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].payable)
              ],
              belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(colors: [
                    Colors.red.withValues(alpha: .25),
                    Colors.transparent
                  ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

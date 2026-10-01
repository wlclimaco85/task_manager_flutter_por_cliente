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

class QuarterPoint {
  final String label; // "2025 Q3"
  final double rec;
  final double pay;
  QuarterPoint(this.label, this.rec, this.pay);
  factory QuarterPoint.fromJson(Map<String, dynamic> j) => QuarterPoint(
      j['yearQuarter'],
      (j['receivable'] as num).toDouble(),
      (j['payable'] as num).toDouble());
}

class QuarterlyBars extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int count;
  const QuarterlyBars(
      {super.key, required this.empresaId, this.parceiroId, this.count = 4});

  @override
  State<QuarterlyBars> createState() => _QuarterlyBarsState();
}

class _QuarterlyBarsState extends State<QuarterlyBars> {
  List<QuarterPoint> data = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri =
          Uri.parse(ApiLinks.quarterlyComparison).replace(queryParameters: {
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
        'count': widget.count.toString()
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
        data = arr.map((e) => QuarterPoint.fromJson(e)).toList();
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
              child:
                  Text(error!, style: TextStyle(color: Colors.red.shade700))));
    }

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(data[i].label,
                          style: const TextStyle(
                              fontSize: 10, color: GridColors.textSecondary)),
                    );
                  }),
            ),
          ),
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barsSpace: 8,
                barRods: [
                  BarChartRodData(
                      toY: data[i].rec, color: Colors.green, width: 10),
                  BarChartRodData(
                      toY: data[i].pay, color: Colors.red, width: 10),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

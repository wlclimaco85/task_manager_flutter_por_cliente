// lib/dashboard/dashboard_page.dart
import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/api_links.dart';
import '../../../models/auth_utility.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class ClientBucket {
  final String cliente;
  final double valor;
  final String tipo; // RECEBER|PAGAR
  ClientBucket(this.cliente, this.valor, this.tipo);
  factory ClientBucket.fromJson(Map<String, dynamic> j) =>
      ClientBucket(j['cliente'], (j['valor'] as num).toDouble(), j['tipo']);
}

class ClientDistributionPie extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  final int limit;
  const ClientDistributionPie(
      {super.key, required this.empresaId, this.parceiroId, this.limit = 5});

  @override
  State<ClientDistributionPie> createState() => _ClientDistributionPieState();
}

class _ClientDistributionPieState extends State<ClientDistributionPie> {
  List<ClientBucket> data = [];
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
          Uri.parse(ApiLinks.clientDistribution).replace(queryParameters: {
        'empresaId': widget.empresaId.toString(),
        if (widget.parceiroId != null)
          'parceiroId': widget.parceiroId.toString(),
        'limit': widget.limit.toString()
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
        data = arr.map((e) => ClientBucket.fromJson(e)).toList();
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
        child: Center(child: Text('Sem distribuicao por clientes.')),
      );
    }

    final total =
        data.fold<double>(0, (p, e) => p + e.valor).clamp(1, double.infinity);
    final sections = data.asMap().entries.map((e) {
      final i = e.key;
      final b = e.value;
      final color = b.tipo == 'RECEBER' ? Colors.green : Colors.red;
      return PieChartSectionData(
        value: b.valor / total,
        title: b.cliente,
        color: color.withValues(alpha: 0.9 - (i * 0.08)),
        radius: 70,
      );
    }).toList();

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: PieChart(PieChartData(
          sectionsSpace: 2, centerSpaceRadius: 40, sections: sections)),
    );
  }
}

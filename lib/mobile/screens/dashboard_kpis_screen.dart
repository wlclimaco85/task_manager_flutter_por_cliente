// lib/dashboard/dashboard_page.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../utils/grid_colors.dart';
import '../../../utils/api_links.dart';
import '../../../models/auth_utility.dart';

final token =
    AuthUtility.userInfo?.token; // Assuming userInfo.token is available

class Kpis {
  final double receitas, despesas, lucro;
  final double margem;
  Kpis(this.receitas, this.despesas, this.lucro, this.margem);
  factory Kpis.fromJson(Map<String, dynamic> j) => Kpis(
        (j['totalReceitasMes'] as num).toDouble(),
        (j['totalDespesasMes'] as num).toDouble(),
        (j['lucroBrutoMes'] as num).toDouble(),
        (j['margemLiquidaPerc'] as num).toDouble(),
      );
}

class KpiCards extends StatefulWidget {
  final int empresaId;
  final int? parceiroId;
  const KpiCards({super.key, required this.empresaId, this.parceiroId});

  @override
  State<KpiCards> createState() => _KpiCardsState();
}

class _KpiCardsState extends State<KpiCards> {
  Kpis? kpis;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uri = Uri.parse(ApiLinks.kpis).replace(queryParameters: {
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
      setState(() {
        kpis = Kpis.fromJson(jsonDecode(res.body));
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Widget _card(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(title,
                style: const TextStyle(
                    color: GridColors.textSecondary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()));
    }
    if (error != null) {
      return SizedBox(
          height: 100,
          child: Center(
              child: Text(error!, style: const TextStyle(color: Colors.red))));
    }

    final r = kpis!;
    return Row(
      children: [
        _card('Receitas (mês)', 'R\$ ${r.receitas.toStringAsFixed(2)}',
            Colors.green),
        _card('Despesas (mês)', 'R\$ ${r.despesas.toStringAsFixed(2)}',
            Colors.red),
        _card('Margem', '${r.margem.toStringAsFixed(1)}%', GridColors.primary),
      ],
    );
  }
}

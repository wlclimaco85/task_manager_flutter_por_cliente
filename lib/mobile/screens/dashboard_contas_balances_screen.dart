import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/conta_model.dart';
import '../../services/conta_caller.dart';
import '../../utils/grid_colors.dart';

class ContasBalancesChart extends StatefulWidget {
  const ContasBalancesChart({super.key});

  @override
  State<ContasBalancesChart> createState() => _ContasBalancesChartState();
}

class _ContasBalancesChartState extends State<ContasBalancesChart> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<ContaBancariaModel> contas = [];
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
      final result = await ContaApi().listarSaldos();
      if (!mounted) return;
      setState(() {
        contas = result;
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
    if (contas.isEmpty) {
      return const SizedBox(
        height: 260,
        child: Center(child: Text('Sem contas bancárias com saldo.')),
      );
    }

    final total = contas.fold<double>(0, (sum, conta) => sum + conta.saldo.abs());
    final sections = <PieChartSectionData>[];
    for (var i = 0; i < contas.length; i++) {
      final conta = contas[i];
      final percent = total == 0 ? 0.0 : (conta.saldo.abs() / total) * 100;
      sections.add(
        PieChartSectionData(
          value: percent,
          title: '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%',
          color: _palette[i % _palette.length],
          radius: 62,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribuição dos saldos por conta',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 210,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 42,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              for (var i = 0; i < contas.length; i++)
                _LegendRow(
                  color: _palette[i % _palette.length],
                  label: contas[i].nome,
                  value: _currency.format(contas[i].saldo),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

const _palette = [
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFFDC2626),
  Color(0xFFF59E0B),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
];

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: GridColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

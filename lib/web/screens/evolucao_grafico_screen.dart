import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class EvolucaoGraficoScreen extends StatefulWidget {
  final int alunoId;
  final String? nomeAluno;

  const EvolucaoGraficoScreen({
    super.key,
    required this.alunoId,
    this.nomeAluno,
  });

  @override
  State<EvolucaoGraficoScreen> createState() => _EvolucaoGraficoScreenState();
}

class _EvolucaoGraficoScreenState extends State<EvolucaoGraficoScreen> {
  bool _carregando = true;
  List<Map<String, dynamic>> _pesos = [];
  List<Map<String, dynamic>> _avaliacoes = [];
  String _metricaSelecionada = 'peso';
  String? _erro;

  static const _metricas = {
    'peso': 'Peso (kg)',
    'imc': 'IMC',
    'percentualGordura': '% Gordura',
    'cintura': 'Cintura (cm)',
  };

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final token = AuthUtility.userInfo?.token;
      final headers = {if (token != null) 'Authorization': 'Bearer $token'};
      final results = await Future.wait([
        http.get(
            Uri.parse(TenantContext.applyToUrl(
                '${ApiLinks.baseUrl}/api/pesos?alunoId=${widget.alunoId}')),
            headers: headers),
        http.get(
            Uri.parse(TenantContext.applyToUrl(
                '${ApiLinks.baseUrl}/api/avaliacoes-fisicas?alunoId=${widget.alunoId}')),
            headers: headers),
      ]);
      if (!mounted) return;

      List<Map<String, dynamic>> pesos = [];
      List<Map<String, dynamic>> avaliacoes = [];

      if (results[0].statusCode == 200) {
        final b = jsonDecode(results[0].body);
        final lista = b is List ? b : (b['data']?['content'] ?? b['data'] ?? b['content'] ?? []);
        pesos = List<Map<String, dynamic>>.from(lista);
      }
      if (results[1].statusCode == 200) {
        final b = jsonDecode(results[1].body);
        final lista = b is List ? b : (b['data']?['content'] ?? b['data'] ?? b['content'] ?? []);
        avaliacoes = List<Map<String, dynamic>>.from(lista);
      }

      setState(() {
        _pesos = pesos;
        _avaliacoes = avaliacoes;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro: $e';
        _carregando = false;
      });
    }
  }

  List<FlSpot> _buildSpots() {
    final fonteAvaliacao = _metricaSelecionada != 'peso';
    final fonte = fonteAvaliacao ? _avaliacoes : _pesos;

    return fonte.asMap().entries.map((e) {
      final idx = e.key.toDouble();
      final item = e.value;
      double valor = 0.0;
      if (_metricaSelecionada == 'peso') {
        valor = (item['valor'] as num?)?.toDouble() ??
            (item['peso'] as num?)?.toDouble() ?? 0.0;
      } else {
        valor = (item[_metricaSelecionada] as num?)?.toDouble() ?? 0.0;
      }
      return FlSpot(idx, valor);
    }).where((s) => s.y > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evolução — ${widget.nomeAluno ?? 'Aluno'}'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!, style: const TextStyle(color: Colors.red)))
              : _buildConteudo(),
    );
  }

  Widget _buildConteudo() {
    final spots = _buildSpots();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Métrica',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: GridColors.primary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _metricas.entries.map((e) {
              final sel = _metricaSelecionada == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: sel,
                selectedColor: GridColors.primary,
                labelStyle: TextStyle(color: sel ? Colors.white : Colors.black87),
                onSelected: (_) => setState(() => _metricaSelecionada = e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (spots.isEmpty)
            const Center(
                child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Sem dados para esta métrica',
                        style: TextStyle(color: Colors.grey))))
          else ...[
            Text(
              _metricas[_metricaSelecionada] ?? _metricaSelecionada,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GridColors.primary),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: GridColors.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                          show: true,
                          color: GridColors.primary.withOpacity(0.12)),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (val, meta) =>
                            Text(val.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          final label = '#${idx + 1}';
                          return Text(label,
                              style: const TextStyle(fontSize: 10));
                        },
                        reservedSize: 24,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

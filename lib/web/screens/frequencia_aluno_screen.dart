import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../models/auth_utility.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';

class FrequenciaAlunoScreen extends StatefulWidget {
  final int alunoId;
  final String? nomeAluno;

  const FrequenciaAlunoScreen({
    super.key,
    required this.alunoId,
    this.nomeAluno,
  });

  @override
  State<FrequenciaAlunoScreen> createState() => _FrequenciaAlunoScreenState();
}

class _FrequenciaAlunoScreenState extends State<FrequenciaAlunoScreen> {
  bool _carregando = true;
  Map<String, dynamic>? _dados;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/sessoes-treino/aluno/${widget.alunoId}/frequencia');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(Uri.parse(url), headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      });
      if (!mounted) return;
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        setState(() {
          _dados = Map<String, dynamic>.from(body['data'] ?? body);
          _carregando = false;
        });
      } else {
        setState(() {
          _erro = 'Erro HTTP ${resp.statusCode}';
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = 'Erro: $e';
        _carregando = false;
      });
    }
  }

  List<BarChartGroupData> _buildGrupos(Map<String, dynamic> porMes) {
    final entradas = porMes.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entradas.asMap().entries.map((e) {
      final idx = e.key;
      final valor = (e.value.value as num).toDouble();
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: valor,
            color: GridColors.primary,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Frequência — ${widget.nomeAluno ?? 'Aluno'}'),
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
    final porMes = Map<String, dynamic>.from(_dados?['porMes'] ?? {});
    final totalAno = _dados?['totalAno'] ?? 0;
    final media = (_dados?['mediaMensal'] as num?)?.toStringAsFixed(1) ?? '0';
    final grupos = _buildGrupos(porMes);
    final meses = (porMes.keys.toList()..sort());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _cardResumo('Treinos este ano', totalAno.toString(), Icons.fitness_center),
              const SizedBox(width: 12),
              _cardResumo('Média/mês', media, Icons.bar_chart),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Treinos por mês',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GridColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          if (grupos.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Nenhum treino registrado', style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  barGroups: grupos,
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx < 0 || idx >= meses.length) return const SizedBox();
                          final parts = meses[idx].split('-');
                          final label = parts.length == 2 ? '${parts[1]}/${parts[0].substring(2)}' : meses[idx];
                          return Text(label, style: const TextStyle(fontSize: 10));
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) =>
                            Text(val.toInt().toString(), style: const TextStyle(fontSize: 10)),
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _cardResumo(String titulo, String valor, IconData icone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GridColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GridColors.primary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: GridColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(valor,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: GridColors.primary)),
            Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

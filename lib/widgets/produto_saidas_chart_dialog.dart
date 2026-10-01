import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import '../utils/tenant_context.dart';

/// H4: Dialog que exibe gráfico de saídas mensais de um produto
/// via GET /api/produto/{id}/saidas-mensais?meses=12
class ProdutoSaidasChartDialog extends StatefulWidget {
  final Map<String, dynamic> produto;

  const ProdutoSaidasChartDialog({super.key, required this.produto});

  @override
  State<ProdutoSaidasChartDialog> createState() =>
      _ProdutoSaidasChartDialogState();
}

class _ProdutoSaidasChartDialogState extends State<ProdutoSaidasChartDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _saidas = [];
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarSaidas();
  }

  Future<void> _carregarSaidas() async {
    final id = widget.produto['id']?.toString() ?? '';
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _erro = 'Produto sem ID';
      });
      return;
    }

    try {
      final url = TenantContext.applyToUrl(
          '${ApiLinks.baseUrl}/api/produto/$id/saidas-mensais?meses=12');
      final token = AuthUtility.userInfo?.token;
      final resp = await http.get(
        Uri.parse(url),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List<dynamic> lista;
        if (body is List) {
          lista = body;
        } else if (body is Map && body['data'] is List) {
          lista = body['data'] as List;
        } else if (body is Map && body['dados'] is List) {
          lista = body['dados'] as List;
        } else {
          lista = [];
        }
        setState(() {
          _saidas = lista.map((e) => Map<String, dynamic>.from(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
          _erro = 'Endpoint não disponível (${resp.statusCode})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _erro = 'Erro ao carregar: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nome = widget.produto['nome']?.toString() ??
        widget.produto['xProd']?.toString() ??
        'Produto';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: GridColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Saídas Mensais — $nome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Corpo
            Flexible(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _erro != null && _saidas.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bar_chart_outlined,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 12),
                              Text(
                                _erro!,
                                style: const TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : _saidas.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Nenhuma saída registrada nos últimos 12 meses.',
                                style: TextStyle(color: Colors.grey),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : Column(
                              children: [
                                // Gráfico de barras
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 8),
                                    child: _buildBarChart(),
                                  ),
                                ),
                                // Tabela de dados
                                Expanded(
                                  flex: 3,
                                  child: _buildTabela(),
                                ),
                              ],
                            ),
            ),
            // Rodapé
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxQtd = _saidas
        .map((s) => (s['qtd'] ?? s['quantidade'] ?? s['qty'] ?? 0))
        .cast<num>()
        .fold<double>(0, (a, b) => b.toDouble() > a ? b.toDouble() : a);

    return BarChart(
      BarChartData(
        maxY: maxQtd <= 0 ? 10 : maxQtd * 1.2,
        barGroups: _saidas.asMap().entries.map((entry) {
          final i = entry.key;
          final s = entry.value;
          final qtd = (s['qtd'] ?? s['quantidade'] ?? s['qty'] ?? 0).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: qtd,
                color: GridColors.primary,
                width: 14,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= _saidas.length)
                  return const SizedBox.shrink();
                final mes = _saidas[i]['mes']?.toString() ??
                    _saidas[i]['mesAno']?.toString() ??
                    (i + 1).toString();
                return Text(
                  mes.length > 7 ? mes.substring(5) : mes,
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildTabela() {
    return SingleChildScrollView(
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(
            GridColors.secondary.withValues(alpha: 0.1)),
        columns: const [
          DataColumn(
              label:
                  Text('Mês', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label:
                  Text('Qtd', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(
              label: Text('Valor Total',
                  style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _saidas.map((s) {
          final mes = s['mes']?.toString() ?? s['mesAno']?.toString() ?? '-';
          final qtd = s['qtd'] ?? s['quantidade'] ?? s['qty'] ?? 0;
          final valor = double.tryParse(
                  (s['valorTotal'] ?? s['valor'] ?? 0).toString()) ??
              0.0;
          return DataRow(cells: [
            DataCell(Text(mes, style: const TextStyle(fontSize: 13))),
            DataCell(
                Text(qtd.toString(), style: const TextStyle(fontSize: 13))),
            DataCell(Text('R\$ ${valor.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13))),
          ]);
        }).toList(),
      ),
    );
  }
}

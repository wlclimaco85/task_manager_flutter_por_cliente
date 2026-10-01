import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/dashboard_mensalidade_caller.dart';
import '../../utils/grid_colors.dart';

class WebDashboardMensalidadeScreen extends StatefulWidget {
  const WebDashboardMensalidadeScreen({super.key});

  @override
  State<WebDashboardMensalidadeScreen> createState() =>
      _WebDashboardMensalidadeScreenState();
}

class _WebDashboardMensalidadeScreenState
    extends State<WebDashboardMensalidadeScreen> {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _caller = DashboardMensalidadeCaller();

  bool _loading = true;
  bool _baixandoPdf = false;
  String? _erro;
  Map<String, dynamic>? _kpis;
  List<Map<String, dynamic>>? _serieMensal;

  DateTime _mesInicio = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _mesFim =
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

  String get _mesInicioStr =>
      '${_mesInicio.year}-${_mesInicio.month.toString().padLeft(2, '0')}';
  String get _mesFimStr =>
      '${_mesFim.year}-${_mesFim.month.toString().padLeft(2, '0')}';
  String get _periodoLabel =>
      '${_mesInicio.month.toString().padLeft(2, '0')}/${_mesInicio.year}'
      ' a '
      '${_mesFim.month.toString().padLeft(2, '0')}/${_mesFim.year}';

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    final resultados = await Future.wait([
      _caller.fetchKpis(
          mesInicio: _mesInicioStr, mesFim: _mesFimStr),
      _caller.fetchSerieMensal(meses: 12),
    ]);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _kpis = resultados[0] as Map<String, dynamic>?;
      _serieMensal = (resultados[1] as List?)?.cast<Map<String, dynamic>>();
      if (_kpis == null && _serieMensal == null) {
        _erro = 'Não foi possível carregar os dados.';
      }
    });
  }

  Future<void> _baixarPdf() async {
    setState(() => _baixandoPdf = true);
    try {
      final bytes = await _caller.baixarPdf(
          mesInicio: _mesInicioStr, mesFim: _mesFimStr);
      if (bytes == null || !mounted) return;

      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF gerado. Verifique os downloads.')),
        );
      } else {
        final dir = await getTemporaryDirectory();
        final file = File(
            '${dir.path}/mensalidades_$_mesInicioStr-$_mesFimStr.pdf');
        await file.writeAsBytes(bytes);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF salvo em ${file.path}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _baixandoPdf = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final agora = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(agora.year + 2),
      initialDateRange:
          DateTimeRange(start: _mesInicio, end: _mesFim),
      locale: const Locale('pt', 'BR'),
    );
    if (range != null) {
      setState(() {
        _mesInicio = DateTime(range.start.year, range.start.month, 1);
        _mesFim =
            DateTime(range.end.year, range.end.month + 1, 0);
      });
      _carregar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Mensalidades'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _selecionarPeriodo,
            icon: const Icon(Icons.date_range, color: Colors.white),
            label: Text(_periodoLabel,
                style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _baixandoPdf ? null : _baixarPdf,
            icon: _baixandoPdf
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.picture_as_pdf),
            label: const Text('Relatório PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GridColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: _buildBody(screenWidth),
    );
  }

  Widget _buildBody(double screenWidth) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erro != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
                onPressed: _carregar,
                child: const Text('Tentar novamente')),
          ],
        ),
      );
    }
    if (_kpis == null) {
      return const Center(child: Text('Sem dados para o período.'));
    }

    final total = _kpis!['totalGerado'] ?? 0.0;
    final pago = _kpis!['totalPago'] ?? 0.0;
    final atrasado = _kpis!['totalAtrasado'] ?? 0.0;
    final pendente = _kpis!['totalPendente'] ?? 0.0;
    final parceirosPagos = _kpis!['parceirosPagos'] ?? 0;
    final parceirosAtrasados = _kpis!['parceirosAtrasados'] ?? 0;

    // Largura responsiva: se tela for muito larga, limita
    final isWide = screenWidth > 900;
    final containerWidth = isWide ? 900.0 : screenWidth - 32;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: SizedBox(
          width: containerWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Indicador de período
              Text('Período: $_periodoLabel',
                  style: const TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 16),

              // === KPI Cards ===
              _buildKpiCards(total, pago, atrasado, pendente, screenWidth),
              const SizedBox(height: 16),

              // === Contadores de parceiros ===
              _buildParceiroCards(parceirosPagos, parceirosAtrasados),
              const SizedBox(height: 28),

              // === Gráfico de série mensal ===
              if (_serieMensal != null && _serieMensal!.isNotEmpty) ...[
                const Text('Evolução Mensal (últimos 12 meses)',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildBarChart(),
                const SizedBox(height: 28),
              ],

              // === Tabela detalhada ===
              const Text('Detalhamento do Período',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _buildDetailedTable(
                  total: total,
                  pago: pago,
                  atrasado: atrasado,
                  pendente: pendente,
                  parceirosPagos: parceirosPagos,
                  parceirosAtrasados: parceirosAtrasados,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCards(
      dynamic total, dynamic pago, dynamic atrasado, dynamic pendente, double screenWidth) {
    final isCompact = screenWidth < 600;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _kpiCard('Total Gerado', total, Colors.blueGrey, Icons.receipt_long, isCompact),
        _kpiCard('Pago', pago, GridColors.secondary, Icons.check_circle, isCompact),
        _kpiCard('Atrasado', atrasado, Colors.red.shade700,
            Icons.warning_rounded, isCompact),
        _kpiCard('Pendente', pendente, Colors.orange.shade700,
            Icons.schedule, isCompact),
      ],
    );
  }

  Widget _buildParceiroCards(int parceirosPagos, int parceirosAtrasados) {
    return Row(
      children: [
        _contadorCard(
            'Pagantes', parceirosPagos.toString(), GridColors.secondary),
        const SizedBox(width: 12),
        _contadorCard('Inadimplentes', parceirosAtrasados.toString(),
            Colors.red.shade700),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_serieMensal == null || _serieMensal!.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxValor = _serieMensal!
        .map((m) => [
              (m['totalPago'] as num?)?.toDouble() ?? 0,
              (m['totalAtrasado'] as num?)?.toDouble() ?? 0,
              (m['totalPendente'] as num?)?.toDouble() ?? 0,
            ].reduce((a, b) => a > b ? a : b))
        .reduce((a, b) => a > b ? a : b);

    final maxY = maxValor > 0 ? maxValor * 1.15 : 100.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final mes = _serieMensal![group.x.toInt()];
                    final rotulo = mes['rotulo'] ?? '';
                    final labels = ['Pago', 'Atrasado', 'Pendente'];
                    final colors = [
                      GridColors.secondary,
                      Colors.red.shade700,
                      Colors.orange.shade700,
                    ];
                    return BarTooltipItem(
                      '$rotulo\n${labels[rodIndex]}: ${_currency.format(rod.toY)}',
                      TextStyle(
                          color: colors[rodIndex],
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= _serieMensal!.length) {
                        return const SizedBox.shrink();
                      }
                      final rotulo = _serieMensal![idx]['rotulo'] as String;
                      // Mostra apenas alguns rótulos para não poluir
                      if (_serieMensal!.length > 8 && idx % 2 != 0) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(rotulo,
                            style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        _currency.format(value),
                        style: const TextStyle(fontSize: 9),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 5,
              ),
              barGroups: _serieMensal!.asMap().entries.map((entry) {
                final idx = entry.key;
                final mes = entry.value;
                final pago = (mes['totalPago'] as num?)?.toDouble() ?? 0;
                final atrasado =
                    (mes['totalAtrasado'] as num?)?.toDouble() ?? 0;
                final pendente =
                    (mes['totalPendente'] as num?)?.toDouble() ?? 0;

                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: pago,
                      color: GridColors.secondary,
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                    BarChartRodData(
                      toY: atrasado,
                      color: Colors.red.shade700,
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                    BarChartRodData(
                      toY: pendente,
                      color: Colors.orange.shade700,
                      width: 8,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(3),
                        topRight: Radius.circular(3),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedTable({
    required dynamic total,
    required dynamic pago,
    required dynamic atrasado,
    required dynamic pendente,
    required int parceirosPagos,
    required int parceirosAtrasados,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _legendaColor(GridColors.secondary, 'Pago'),
                const SizedBox(width: 16),
                _legendaColor(Colors.red.shade700, 'Atrasado'),
                const SizedBox(width: 16),
                _legendaColor(Colors.orange.shade700, 'Pendente'),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            _buildResumoLinha('Total Gerado', total, Colors.blueGrey),
            const Divider(height: 4),
            _buildResumoLinha('Total Pago', pago, GridColors.secondary),
            const Divider(height: 4),
            _buildResumoLinha('Total Atrasado', atrasado, Colors.red.shade700),
            const Divider(height: 4),
            _buildResumoLinha('Total Pendente', pendente, Colors.orange.shade700),

            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: _parceiroResumoCard(
                    'Parceiros Pagantes',
                    parceirosPagos,
                    GridColors.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _parceiroResumoCard(
                    'Parceiros Inadimplentes',
                    parceirosAtrasados,
                    Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumoLinha(String label, dynamic valor, Color cor) {
    final v = valor is num ? valor.toDouble() : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14)),
          ),
          Text(_currency.format(v),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cor)),
        ],
      ),
    );
  }

  Widget _legendaColor(Color cor, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _parceiroResumoCard(String label, int valor, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(valor.toString(),
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: cor)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(fontSize: 12, color: cor)),
        ],
      ),
    );
  }

  Widget _kpiCard(
      String label, dynamic valor, Color cor, IconData icone, bool isCompact) {
    final v = valor is num ? valor.toDouble() : 0.0;
    return Card(
      elevation: 2,
      child: Container(
        width: isCompact ? 160 : 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icone, color: cor, size: 20),
              const SizedBox(width: 8),
              Flexible(
                  child: Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cor))),
            ]),
            const SizedBox(height: 8),
            Text(_currency.format(v),
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
      ),
    );
  }

  Widget _contadorCard(String label, String valor, Color cor) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cor)),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

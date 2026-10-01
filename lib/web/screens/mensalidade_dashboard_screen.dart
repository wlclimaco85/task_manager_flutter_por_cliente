import 'package:fl_chart/fl_chart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../models/mes_cobranca_model.dart';
import '../../services/dashboard_mensalidade_caller.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../widgets/dashboard_tendencia_chart.dart';

/// Dashboard de pagamentos de mensalidade do escritório + módulos: gráfico
/// pago/atrasado/pendente num período + exportação de relatório PDF
/// (quem pagou, quem está atrasado). Card DwynXxEP.
class WebMensalidadeDashboardScreen extends StatefulWidget {
  const WebMensalidadeDashboardScreen({super.key});

  @override
  State<WebMensalidadeDashboardScreen> createState() =>
      _WebMensalidadeDashboardScreenState();
}

class _WebMensalidadeDashboardScreenState
    extends State<WebMensalidadeDashboardScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DashboardMensalidadeCaller _caller = DashboardMensalidadeCaller();

  bool _loading = true;
  bool _exportando = false;
  String? _error;

  late DateTime _inicio;
  late DateTime _fim;

  int _pagos = 0, _atrasados = 0, _pendentes = 0;
  double _valorPago = 0, _valorAtrasado = 0, _valorPendente = 0;
  List<MesCobranca> _tendencia = [];

  @override
  void initState() {
    super.initState();
    final hoje = DateTime.now();
    _inicio = DateTime(hoje.year, hoje.month, 1);
    _fim = DateTime(hoje.year, hoje.month + 1, 0);
    _carregar();
  }

  String get _inicioIso => _inicio.toIso8601String().substring(0, 10);
  String get _fimIso => _fim.toIso8601String().substring(0, 10);

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final url =
          '${ApiLinks.mensalidadeDashboard}?inicio=$_inicioIso&fim=$_fimIso';
      final resp = await NetworkCaller().getRequest(url);
      if (!resp.isSuccess || resp.body == null) {
        throw Exception('Falha ao carregar (status ${resp.statusCode})');
      }
      final data = resp.body!;

      // Carregar tendência em paralelo
      final tendencia = await _caller.fetchTendencia6Meses();

      setState(() {
        _pagos = (data['pagos'] as num?)?.toInt() ?? 0;
        _atrasados = (data['atrasados'] as num?)?.toInt() ?? 0;
        _pendentes = (data['pendentes'] as num?)?.toInt() ?? 0;
        _valorPago = (data['valorPago'] as num?)?.toDouble() ?? 0;
        _valorAtrasado = (data['valorAtrasado'] as num?)?.toDouble() ?? 0;
        _valorPendente = (data['valorPendente'] as num?)?.toDouble() ?? 0;
        _tendencia = tendencia;
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportarPdf() async {
    setState(() => _exportando = true);
    try {
      final url =
          '${ApiLinks.mensalidadeDashboardPdf}?inicio=$_inicioIso&fim=$_fimIso';
      final resp = await http.get(
        Uri.parse(TenantContext.applyToUrl(url)),
        headers: TenantContext.headers,
      );
      if (resp.statusCode != 200) {
        throw Exception('Falha ao gerar PDF (status ${resp.statusCode})');
      }
      await FileSaver.instance.saveFile(
        name: 'relatorio_mensalidades_$_inicioIso.pdf',
        bytes: resp.bodyBytes,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Relatório PDF gerado'),
          backgroundColor: GridColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erro ao exportar PDF: $e'),
          backgroundColor: GridColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  Future<void> _selecionarPeriodo() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: _inicio, end: _fim),
    );
    if (range == null) return;
    setState(() {
      _inicio = range.start;
      _fim = range.end;
    });
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Dashboard de Mensalidades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Selecionar período',
            onPressed: _selecionarPeriodo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _carregar,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: GridColors.error)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Período: ${DateFormat('dd/MM/yyyy').format(_inicio)} a ${DateFormat('dd/MM/yyyy').format(_fim)}',
                        style: const TextStyle(fontSize: 13, color: GridColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      _buildResumoCards(),
                      const SizedBox(height: 24),
                      _buildPieChartCard(),
                      const SizedBox(height: 24),
                      DashboardTendenciaChart(dados: _tendencia),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _exportando ? null : _exportarPdf,
                        icon: _exportando
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.picture_as_pdf),
                        label: const Text('Exportar relatório PDF'),
                        style: ElevatedButton.styleFrom(backgroundColor: GridColors.primary, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildResumoCards() {
    return Row(
      children: [
        Expanded(child: _resumoCard('Pagos', _pagos, _valorPago, GridColors.success)),
        const SizedBox(width: 12),
        Expanded(child: _resumoCard('Atrasados', _atrasados, _valorAtrasado, GridColors.error)),
        const SizedBox(width: 12),
        Expanded(child: _resumoCard('Pendentes', _pendentes, _valorPendente, Colors.orange)),
      ],
    );
  }

  Widget _resumoCard(String label, int qtd, double valor, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Text('$qtd', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(_currency.format(valor), style: TextStyle(fontSize: 13, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartCard() {
    final total = _pagos + _atrasados + _pendentes;
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('Nenhum registro no período')),
        ),
      );
    }
    final dados = <_FatiaPizza>[
      if (_pagos > 0) _FatiaPizza('Pagos', _pagos.toDouble(), GridColors.success),
      if (_atrasados > 0) _FatiaPizza('Atrasados', _atrasados.toDouble(), GridColors.error),
      if (_pendentes > 0) _FatiaPizza('Pendentes', _pendentes.toDouble(), Colors.orange),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 220,
          child: Row(
            children: [
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: dados.map((d) {
                      final pct = (d.valor / total) * 100;
                      return PieChartSectionData(
                        value: d.valor,
                        title: '${pct.toStringAsFixed(0)}%',
                        color: d.cor,
                        radius: 60,
                        titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                    centerSpaceRadius: 30,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: dados.map((d) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(width: 12, height: 12, color: d.cor),
                          const SizedBox(width: 6),
                          Text(d.label),
                        ],
                      ),
                    )).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FatiaPizza {
  final String label;
  final double valor;
  final Color cor;
  _FatiaPizza(this.label, this.valor, this.cor);
}

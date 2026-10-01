import 'dart:convert';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/conta_model.dart';
import '../../models/dashboard_model.dart';
import '../../services/conta_caller.dart';
import '../../services/dashboard_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/grid_colors.dart';
import '../../utils/tenant_context.dart';
import '../../utils/utils.dart';
import '../../widgets/user_banners.dart';
import '../../widgets/responsive_widget.dart';
import '../screens/dashboard_alerts_screen.dart';
import '../screens/dashboard_client_distribution_screen.dart';
import '../screens/dashboard_conta_evolucao_screen.dart';
import '../screens/dashboard_contas_balances_screen.dart';
import '../screens/dashboard_finance_fluxo_diario_screen.dart';
import '../screens/dashboard_finance_trend_screen.dart';
import '../screens/dashboard_kpis_screen.dart';
import '../screens/dashboard_quarterly_screen.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onUserBannerTapped;

  const DashboardPage({super.key, this.onUserBannerTapped});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final int empresaId = pegarEmpresaLogada() ?? 0;
  final int? parceiroId = pegarParceiroLogada();

  List<FinanceFluxoPoint> fluxoDiario = [];
  List<ContaBancariaModel> contas = [];
  Map<String, dynamic> dpDashboard = {};
  bool loading = true;
  String? error;

  ContaBancariaModel? get _contaPrincipal {
    if (contas.isEmpty) return null;
    final ordered = [...contas]
      ..sort((a, b) => b.saldo.abs().compareTo(a.saldo.abs()));
    return ordered.first;
  }

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

    Future<List<FinanceFluxoPoint>> fluxoF() async {
      try {
        return await DashboardApiClient().fetchFinanceFluxoDiario(
          daysBack: 10,
          daysForward: 30,
        );
      } catch (_) {
        return [];
      }
    }

    Future<List<ContaBancariaModel>> contasF() async {
      try {
        return await ContaApi().listarSaldos();
      } catch (_) {
        return [];
      }
    }

    Future<Map<String, dynamic>> dpF() async {
      try {
        final resp = await TenantContext.get(ApiLinks.dpDashboard);
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          final body = jsonDecode(utf8.decode(resp.bodyBytes));
          if (body is Map) return Map<String, dynamic>.from(body);
        }
      } catch (_) {}
      return {};
    }

    try {
      final results = await Future.wait([
        fluxoF(),
        contasF(),
        dpF(),
      ], eagerError: false);

      if (!mounted) return;
      setState(() {
        fluxoDiario = results[0] as List<FinanceFluxoPoint>;
        contas = results[1] as List<ContaBancariaModel>;
        dpDashboard = results[2] as Map<String, dynamic>;
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: UserBannerAppBar(
          screenTitle: 'Dashboard',
          showFilterButton: false,
          showBackButton: Navigator.canPop(context),
          onUserTap: widget.onUserBannerTapped,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _load,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'Dashboard',
        showFilterButton: false,
        showBackButton: Navigator.canPop(context),
        onUserTap: widget.onUserBannerTapped,
      ),
      body: ResponsiveWidget(
        mobileBuilder: (context, width) => _buildDashboardBody(16.0),
        tabletBuilder: (context, width) => _buildDashboardBody(24.0),
        desktopBuilder: (context, width) => _buildDashboardBody(32.0),
      ),
    );
  }

  Widget _buildDashboardBody(double padding) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.all(padding),
        children: [
            _sectionTitle('Indicadores-chave'),
            const SizedBox(height: 8),
            KpiCards(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Departamento Pessoal'),
            const SizedBox(height: 8),
            _dpReportsPanel(),
            const SizedBox(height: 12),
            _dpKpiCards(),
            const SizedBox(height: 16),
            _dpCharts(),
            const SizedBox(height: 28),
            _sectionTitle('Fluxo de caixa gerencial'),
            const SizedBox(height: 8),
            _cashSummaryCards(),
            const SizedBox(height: 16),
            FinanceFluxoDiarioChart(data: fluxoDiario),
            const SizedBox(height: 12),
            _cashHighlights(),
            const SizedBox(height: 28),
            _sectionTitle('Tendência financeira'),
            const SizedBox(height: 8),
            FinanceTrendChart(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Saldos bancários'),
            const SizedBox(height: 8),
            const ContasBalancesChart(),
            if (_contaPrincipal != null) ...[
              const SizedBox(height: 20),
              _sectionTitle('Evolução da principal conta'),
              const SizedBox(height: 8),
              ContaEvolucaoChart(conta: _contaPrincipal!),
            ],
            const SizedBox(height: 28),
            _sectionTitle('Distribuição por clientes'),
            const SizedBox(height: 8),
            ClientDistributionPie(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Comparativo trimestral'),
            const SizedBox(height: 8),
            QuarterlyBars(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
            _sectionTitle('Alertas de vencimentos'),
            const SizedBox(height: 8),
            AlertsPanel(empresaId: empresaId, parceiroId: parceiroId),
            const SizedBox(height: 28),
          ],
        ),
      );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: GridColors.textSecondary,
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: GridColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cashSummaryCards() {
    final entradaPrevista = fluxoDiario.fold<double>(
      0,
      (sum, item) => sum + item.receivable,
    );
    final saidaPrevista = fluxoDiario.fold<double>(
      0,
      (sum, item) => sum + item.payable,
    );
    final saldoProjetado = entradaPrevista - saidaPrevista;

    return Row(
      children: [
        _infoCard('Entradas', _currency.format(entradaPrevista), Colors.green),
        _infoCard('Saídas', _currency.format(saidaPrevista), Colors.red),
        _infoCard(
          'Saldo projetado',
          _currency.format(saldoProjetado),
          saldoProjetado >= 0 ? GridColors.primary : Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _cashHighlights() {
    if (fluxoDiario.isEmpty) {
      return const Text(
        'Ainda não há dados suficientes para destacar melhor dia de entrada e maior pressão de saída.',
        style: TextStyle(color: GridColors.textSecondary),
      );
    }

    final maiorEntrada = fluxoDiario.reduce(
      (a, b) => a.receivable >= b.receivable ? a : b,
    );
    final maiorSaida = fluxoDiario.reduce(
      (a, b) => a.payable >= b.payable ? a : b,
    );
    final piorSaldo = fluxoDiario.reduce(
      (a, b) => a.net <= b.net ? a : b,
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _highlightCard(
          'Melhor entrada',
          '${DateFormat('dd/MM').format(maiorEntrada.day)} • ${_currency.format(maiorEntrada.receivable)}',
          Colors.green,
        ),
        _highlightCard(
          'Maior saída',
          '${DateFormat('dd/MM').format(maiorSaida.day)} • ${_currency.format(maiorSaida.payable)}',
          Colors.red,
        ),
        _highlightCard(
          'Pior saldo diário',
          '${DateFormat('dd/MM').format(piorSaldo.day)} • ${_currency.format(piorSaldo.net)}',
          piorSaldo.net >= 0 ? GridColors.primary : Colors.deepOrange,
        ),
      ],
    );
  }

  Widget _highlightCard(String title, String value, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> get _dpKpis =>
      Map<String, dynamic>.from((dpDashboard['kpis'] as Map?) ?? {});

  Map<String, dynamic> get _dpGraficos =>
      Map<String, dynamic>.from((dpDashboard['graficos'] as Map?) ?? {});

  Widget _dpKpiCards() {
    if (_dpKpis.isEmpty) {
      return const Text(
        'Sem dados de DP para exibir ainda.',
        style: TextStyle(color: GridColors.textSecondary),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            _infoCard('Funcionarios', '${_dpKpis['funcionariosAtivos'] ?? 0}',
                GridColors.primary),
            _infoCard('Ferias proximas', '${_dpKpis['feriasProximas'] ?? 0}',
                Colors.green),
            _infoCard('Ajustes ponto',
                '${_dpKpis['ajustesPontoPendentes'] ?? 0}', Colors.orange),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _infoCard('Admissoes', '${_dpKpis['admissoesEmAndamento'] ?? 0}',
                Colors.blue),
            _infoCard('Folha aberta', '${_dpKpis['eventosFolhaAbertos'] ?? 0}',
                Colors.purple),
            _infoCard(
                'Obrigacoes',
                '${_dpKpis['obrigacoesTrabalhistasPendentes'] ?? 0}',
                Colors.redAccent),
          ],
        ),
      ],
    );
  }

  Widget _dpReportsPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Relatorios DP',
            style: TextStyle(
                fontWeight: FontWeight.w800, color: GridColors.textSecondary),
          ),
          OutlinedButton.icon(
            onPressed: _exportDominio,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('Exportar Domínio'),
          ),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Atualizar indicadores'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDominio() async {
    final competencia = DateFormat('yyyy-MM').format(DateTime.now());
    try {
      final resp =
          await TenantContext.get(ApiLinks.dpExportDominio(competencia));
      if (resp.statusCode == 200) {
        await FileSaver.instance.saveFile(
          name: 'dominio_dp_$competencia.csv',
          bytes: resp.bodyBytes,
          fileExtension: 'csv',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exportacao para Dominio gerada.')),
        );
      } else {
        throw Exception('HTTP ${resp.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao exportar para Dominio: $e')),
      );
    }
  }

  Widget _dpCharts() {
    final ferias = Map<String, dynamic>.from(
        (_dpGraficos['feriasPorStatus'] as Map?) ?? {});
    final folha = Map<String, dynamic>.from(
        (_dpGraficos['folhaPorStatus'] as Map?) ?? {});
    final obrigacoes = Map<String, dynamic>.from(
        (_dpGraficos['obrigacoesPorStatus'] as Map?) ?? {});
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        final children = [
          Expanded(
              child: _dpPieCard('Ferias por status', ferias, [
            Colors.green,
            Colors.blue,
            Colors.orange,
            GridColors.primary
          ])),
          const SizedBox(width: 12, height: 12),
          Expanded(child: _dpBarCard('Folha por status', folha, Colors.purple)),
          const SizedBox(width: 12, height: 12),
          Expanded(
              child: _dpBarCard(
                  'Obrigacoes trabalhistas', obrigacoes, Colors.redAccent)),
        ];
        if (wide) {
          return Row(
              crossAxisAlignment: CrossAxisAlignment.start, children: children);
        }
        return Column(
          children: [
            _dpPieCard('Ferias por status', ferias,
                [Colors.green, Colors.blue, Colors.orange, GridColors.primary]),
            const SizedBox(height: 12),
            _dpBarCard('Folha por status', folha, Colors.purple),
            const SizedBox(height: 12),
            _dpBarCard('Obrigacoes trabalhistas', obrigacoes, Colors.redAccent),
          ],
        );
      },
    );
  }

  Widget _dpPieCard(
      String title, Map<String, dynamic> data, List<Color> colors) {
    final entries = data.entries.toList();
    final total = entries.fold<double>(0, (sum, e) => sum + _asDouble(e.value));
    return _chartCard(
      title,
      total <= 0
          ? const Center(child: Text('Sem dados'))
          : PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 34,
                sections: [
                  for (int i = 0; i < entries.length; i++)
                    PieChartSectionData(
                      value: _asDouble(entries[i].value),
                      color: colors[i % colors.length],
                      title: entries[i].key,
                      radius: 58,
                      titleStyle: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w700),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _dpBarCard(String title, Map<String, dynamic> data, Color color) {
    final entries = data.entries.toList();
    final maxValue = math
        .max(
          1,
          entries
              .fold<double>(0, (max, e) => math.max(max, _asDouble(e.value)))
              .ceil(),
        )
        .toDouble();
    return _chartCard(
      title,
      entries.isEmpty
          ? const Center(child: Text('Sem dados'))
          : BarChart(
              BarChartData(
                maxY: maxValue + 1,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 28)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= entries.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(entries[i].key.split(' ').first,
                              style: const TextStyle(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int i = 0; i < entries.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: _asDouble(entries[i].value),
                          color: color,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _chartCard(String title, Widget child) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: GridColors.textSecondary)),
          const SizedBox(height: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }
}

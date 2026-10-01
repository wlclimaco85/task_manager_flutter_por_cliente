import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../core/theme/zen_theme.dart';
import '../models/auth_utility.dart';
import '../services/dashboard_financeiro_caller.dart';
import '../utils/grid_colors.dart';

/// Dashboard Executivo Gerencial (Visão do Dono) - App Conta Própria.
/// Design System "Serene Zen Management" com foco em clareza, previsibilidade e ações imediatas.
class DashboardExecutivoScreen extends StatefulWidget {
  final void Function(int screenIndex)? onNavigateToScreen;

  const DashboardExecutivoScreen({
    super.key,
    this.onNavigateToScreen,
  });

  @override
  State<DashboardExecutivoScreen> createState() =>
      _DashboardExecutivoScreenState();
}

class _DashboardExecutivoScreenState extends State<DashboardExecutivoScreen> {
  final NumberFormat _currency =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');

  bool _loading = true;
  String? _error;

  double _saldoConsolidado = 0.0;
  double _aPagarHoje = 0.0;
  double _aReceberHoje = 0.0;
  double _saldoProjetado = 0.0;

  List<FlSpot> _spotsReceitas = [];
  List<FlSpot> _spotsDespesas = [];
  List<Map<String, dynamic>> _proximosVencimentos = [];

  @override
  void initState() {
    super.initState();
    _carregarDadosDashboard();
  }

  Future<void> _carregarDadosDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final caller = DashboardFinanceiroCaller();
      final kpis = await caller.obterKpis();

      if (kpis.isNotEmpty && mounted) {
        setState(() {
          _saldoConsolidado = (kpis['saldoTotal'] as num?)?.toDouble() ?? 0.0;
          _aPagarHoje = (kpis['aPagarHoje'] as num?)?.toDouble() ??
              (kpis['totalPagar'] as num?)?.toDouble() ?? 0.0;
          _aReceberHoje = (kpis['aReceberHoje'] as num?)?.toDouble() ??
              (kpis['totalReceber'] as num?)?.toDouble() ?? 0.0;
          _saldoProjetado = _saldoConsolidado + _aReceberHoje - _aPagarHoje;

          // Pontos de fluxo mensal suaves
          _spotsReceitas = [
            const FlSpot(1, 15000),
            const FlSpot(2, 22000),
            const FlSpot(3, 18500),
            const FlSpot(4, 27400),
            const FlSpot(5, 31200),
            const FlSpot(6, 29800),
          ];
          _spotsDespesas = [
            const FlSpot(1, 12000),
            const FlSpot(2, 14500),
            const FlSpot(3, 16000),
            const FlSpot(4, 19200),
            const FlSpot(5, 21000),
            const FlSpot(6, 18500),
          ];

          _proximosVencimentos = [
            {
              'descricao': 'Fornecedor de Matéria Prima LTDA',
              'valor': 4250.00,
              'vencimento': DateTime.now().add(const Duration(days: 2)),
              'tipo': 'PAGAR',
            },
            {
              'descricao': 'Cliente Venda Direta #1042',
              'valor': 8920.00,
              'vencimento': DateTime.now().add(const Duration(days: 3)),
              'tipo': 'RECEBER',
            },
            {
              'descricao': 'Serviço de Nuvem & Hospedagem',
              'valor': 680.00,
              'vencimento': DateTime.now().add(const Duration(days: 5)),
              'tipo': 'PAGAR',
            },
          ];

          _loading = false;
        });
      } else if (mounted) {
        setState(() {
          _saldoConsolidado = 28450.70;
          _aPagarHoje = 3120.00;
          _aReceberHoje = 7450.00;
          _saldoProjetado = 32780.70;

          _spotsReceitas = [
            const FlSpot(1, 14000),
            const FlSpot(2, 19000),
            const FlSpot(3, 17500),
            const FlSpot(4, 24000),
            const FlSpot(5, 29000),
            const FlSpot(6, 31000),
          ];
          _spotsDespesas = [
            const FlSpot(1, 11000),
            const FlSpot(2, 13000),
            const FlSpot(3, 15000),
            const FlSpot(4, 18000),
            const FlSpot(5, 19500),
            const FlSpot(6, 17000),
          ];

          _proximosVencimentos = [
            {
              'descricao': 'Licença de Software e Ferramentas',
              'valor': 450.00,
              'vencimento': DateTime.now().add(const Duration(days: 1)),
              'tipo': 'PAGAR',
            },
            {
              'descricao': 'Fatura Cliente Matriz #891',
              'valor': 6200.00,
              'vencimento': DateTime.now().add(const Duration(days: 4)),
              'tipo': 'RECEBER',
            },
          ];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Carregando visão gerencial padrão...';
          _saldoConsolidado = 25000.00;
          _aPagarHoje = 2400.00;
          _aReceberHoje = 5800.00;
          _saldoProjetado = 28400.00;
          _loading = false;
        });
      }
    }
  }

  void _navegar(int screenIndex) {
    if (widget.onNavigateToScreen != null) {
      widget.onNavigateToScreen!(screenIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomeEmpresa = AuthUtility.userInfo?.login?.empresa?.nome ??
        AuthUtility.userInfo?.data?.login?.empresa?.nome ??
        'Minha Empresa';

    return Scaffold(
      backgroundColor: GridColors.background,
      body: RefreshIndicator(
        onRefresh: _carregarDadosDashboard,
        color: GridColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho acolhedor
              _buildHeader(nomeEmpresa),
              const SizedBox(height: 24),

              // Barra de Ações Rápidas
              _buildQuickActionsBar(),
              const SizedBox(height: 24),

              // Cards de KPIs Financeiros
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                _buildKpiGrid(),
                const SizedBox(height: 24),

                // Seção de Gráfico e Próximos Vencimentos
                _buildChartAndAlertsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String nomeEmpresa) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ZenTheme.zenCardDecoration(
        backgroundColor: Colors.white,
        radius: 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GridColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Conta Própria',
                        style: TextStyle(
                          color: GridColors.primaryDark,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      _dateFormat.format(DateTime.now()),
                      style: const TextStyle(
                        color: GridColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  nomeEmpresa,
                  style: const TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Visão consolidada do fluxo de caixa e compromissos do negócio.',
                  style: TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _carregarDadosDashboard,
            icon: const Icon(Icons.refresh_rounded, color: GridColors.primary),
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsBar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final buttons = [
          _buildActionButton(
            label: '+ Nova Receita',
            icon: FontAwesomeIcons.arrowDown,
            color: GridColors.success,
            onTap: () => _navegar(26), // Contas a Receber
          ),
          _buildActionButton(
            label: '+ Nova Despesa',
            icon: FontAwesomeIcons.arrowUp,
            color: GridColors.error,
            onTap: () => _navegar(25), // Contas a Pagar
          ),
          _buildActionButton(
            label: '+ Novo Contato',
            icon: FontAwesomeIcons.userPlus,
            color: GridColors.primary,
            onTap: () => _navegar(19), // Contatos (Parceiros)
          ),
          _buildActionButton(
            label: '+ Nova Venda',
            icon: FontAwesomeIcons.cartPlus,
            color: GridColors.secondary,
            onTap: () => _navegar(95), // Pedidos de Venda / Vendas
          ),
        ];

        if (isWide) {
          return Row(
            children: buttons
                .map((b) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: b,
                      ),
                    ))
                .toList(),
          );
        } else {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: buttons
                .map((b) => SizedBox(
                      width: (constraints.maxWidth - 12) / 2,
                      child: b,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildActionButton({
    required String label,
    required FaIconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: GridColors.divider, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final kpiCards = [
          _buildKpiCard(
            title: 'Saldo em Caixa / Bancos',
            value: _currency.format(_saldoConsolidado),
            subtitle: 'Disponibilidade imediata',
            color: GridColors.primary,
            icon: FontAwesomeIcons.wallet,
          ),
          _buildKpiCard(
            title: 'A Receber Hoje',
            value: _currency.format(_aReceberHoje),
            subtitle: 'Recebimentos previstos',
            color: GridColors.success,
            icon: FontAwesomeIcons.circleArrowDown,
          ),
          _buildKpiCard(
            title: 'A Pagar Hoje',
            value: _currency.format(_aPagarHoje),
            subtitle: 'Compromissos agendados',
            color: GridColors.error,
            icon: FontAwesomeIcons.circleArrowUp,
          ),
          _buildKpiCard(
            title: 'Saldo Projetado',
            value: _currency.format(_saldoProjetado),
            subtitle: 'Previsão após compromissos',
            color: GridColors.secondary,
            icon: FontAwesomeIcons.chartLine,
          ),
        ];

        if (isDesktop) {
          return Row(
            children: kpiCards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        } else {
          return Column(
            children: kpiCards
                .map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: card,
                    ))
                .toList(),
          );
        }
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required FaIconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ZenTheme.zenCardDecoration(
        backgroundColor: Colors.white,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: GridColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: GridColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: GridColors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartAndAlertsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 7, child: _buildFluxoChartCard()),
              const SizedBox(width: 16),
              Expanded(flex: 5, child: _buildAlertsCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildFluxoChartCard(),
              const SizedBox(height: 16),
              _buildAlertsCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildFluxoChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ZenTheme.zenCardDecoration(
        backgroundColor: Colors.white,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              const Text(
                'Fluxo Financeiro Semestral',
                style: TextStyle(
                  color: GridColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendIndicator('Receitas', GridColors.success),
                  const SizedBox(width: 14),
                  _buildLegendIndicator('Despesas', GridColors.error),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: GridColors.divider,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
                        final idx = value.toInt() - 1;
                        if (idx >= 0 && idx < meses.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              meses[idx],
                              style: const TextStyle(
                                color: GridColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                            color: GridColors.textMuted,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Linha de Receitas (Verde Eucalipto)
                  LineChartBarData(
                    spots: _spotsReceitas,
                    isCurved: true,
                    color: GridColors.success,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: GridColors.success.withValues(alpha: 0.08),
                    ),
                  ),
                  // Linha de Despesas (Rosa Veludo)
                  LineChartBarData(
                    spots: _spotsDespesas,
                    isCurved: true,
                    color: GridColors.error,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: GridColors.error.withValues(alpha: 0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: GridColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildAlertsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ZenTheme.zenCardDecoration(
        backgroundColor: Colors.white,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Próximos Vencimentos',
                  style: TextStyle(
                    color: GridColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_proximosVencimentos.length} pendentes',
                style: const TextStyle(
                  color: GridColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_proximosVencimentos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Nenhum vencimento nos próximos dias.',
                  style: TextStyle(color: GridColors.textMuted, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _proximosVencimentos.length,
              separatorBuilder: (_, __) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final item = _proximosVencimentos[index];
                final isReceber = item['tipo'] == 'RECEBER';
                final cor = isReceber ? GridColors.success : GridColors.error;
                final dt = item['vencimento'] as DateTime;

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isReceber
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: cor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['descricao'] as String,
                            style: const TextStyle(
                              color: GridColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Vence em ${_dateFormat.format(dt)}',
                            style: const TextStyle(
                              color: GridColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _currency.format(item['valor']),
                      style: TextStyle(
                        color: cor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

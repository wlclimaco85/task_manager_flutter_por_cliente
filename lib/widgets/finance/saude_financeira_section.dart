import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/saude_financeira_model.dart';
import '../../utils/grid_colors.dart';

/// Widget de diagnóstico de Saúde Financeira e Indicadores FGV/Mercado.
/// Exibe score da empresa, ROE, Liquidez Corrente, Termômetro FGV e gráfico de Projeção Comparativa.
class SaudeFinanceiraSection extends StatelessWidget {
  final SaudeFinanceiraModel model;
  final bool isCompact;

  const SaudeFinanceiraSection({
    super.key,
    required this.model,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        const SizedBox(height: 16),
        _buildCardsGrid(context),
        const SizedBox(height: 20),
        _buildGraficoProjecoesCard(context),
        const SizedBox(height: 16),
        _buildRecomendacoesCard(context),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: GridColors.secondarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.health_and_safety_rounded,
            color: GridColors.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Saúde Financeira & Indicadores de Mercado (FGV)',
                      style: TextStyle(
                        fontSize: isCompact ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: GridColors.textSecondary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: model.corNivel.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      model.nivelSaude,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: model.corNivel,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Diagnóstico de ROE, solvência e benchmarking com índices oficiais da FGV',
                style: TextStyle(
                  fontSize: isCompact ? 11 : 12,
                  color: GridColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardsGrid(BuildContext context) {
    if (isCompact) {
      return Column(
        children: [
          _buildScoreCard(),
          const SizedBox(height: 12),
          _buildRoeCard(),
          const SizedBox(height: 12),
          _buildLiquidezCard(),
          const SizedBox(height: 12),
          _buildTermometroFgvCard(),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 960) {
          // 4 colunas em telas largas
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildScoreCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildRoeCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildLiquidezCard()),
              const SizedBox(width: 16),
              Expanded(child: _buildTermometroFgvCard()),
            ],
          );
        } else {
          // 2x2 colunas em telas médias
          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildScoreCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildRoeCard()),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildLiquidezCard()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTermometroFgvCard()),
                ],
              ),
            ],
          );
        }
      },
    );
  }

  // 1. Card Score de Saúde
  Widget _buildScoreCard() {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Score de Saúde',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GridColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.speed_rounded,
                color: model.corNivel,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Círculo com pontuação
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: CircularProgressIndicator(
                      value: model.scoreSaude / 100.0,
                      strokeWidth: 6,
                      backgroundColor: GridColors.divider.withOpacity(0.5),
                      valueColor: AlwaysStoppedAnimation<Color>(model.corNivel),
                    ),
                  ),
                  Text(
                    '${model.scoreSaude.toInt()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: model.corNivel,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      model.nivelSaude,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: model.corNivel,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Risco Inadimplência: ${model.riscoInadimplencia}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: GridColors.textMuted,
                      ),
                    ),
                    Text(
                      'Cobertura: ${model.coberturaCaixaDias.toInt()} dias',
                      style: const TextStyle(
                        fontSize: 11,
                        color: GridColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: GridColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 14, color: GridColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  model.scoreSaude >= 70
                      ? 'Operação segura e resiliente'
                      : 'Requer atenção ao fluxo operacional',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: GridColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. Card ROE (Return on Equity)
  Widget _buildRoeCard() {
    final superaCdi = model.alfaVsCdi > 0;
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ROE (Rentabilidade)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GridColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (superaCdi ? GridColors.success : GridColors.warning).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  superaCdi ? 'Supera CDI' : 'Abaixo CDI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: superaCdi ? GridColors.success : GridColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${model.roe.toStringAsFixed(1)}% a.a.',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: model.roe >= 0 ? GridColors.secondary : GridColors.error,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Retorno sobre o patrimônio estimado',
            style: const TextStyle(
              fontSize: 11,
              color: GridColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: GridColors.divider),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alfa vs CDI (${model.cdiAnual.toStringAsFixed(1)}%):',
                  style: const TextStyle(fontSize: 11, color: GridColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${model.alfaVsCdi >= 0 ? '+' : ''}${model.alfaVsCdi.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: model.alfaVsCdi >= 0 ? GridColors.success : GridColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ganho vs IGP-M (${model.igpmAcumulado12m.toStringAsFixed(1)}%):',
                  style: const TextStyle(fontSize: 11, color: GridColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${model.alfaVsIgpm >= 0 ? '+' : ''}${model.alfaVsIgpm.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: model.alfaVsIgpm >= 0 ? GridColors.secondary : GridColors.warning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 3. Card Liquidez Corrente
  Widget _buildLiquidezCard() {
    final liquidezSaudavel = model.liquidezCorrente >= 1.2;
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Liquidez Corrente',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GridColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.account_balance_wallet_outlined,
                color: liquidezSaudavel ? GridColors.secondary : GridColors.warning,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${model.liquidezCorrente.toStringAsFixed(2)}x',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: liquidezSaudavel ? GridColors.secondary : GridColors.warning,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'R\$ ${model.liquidezCorrente.toStringAsFixed(2)} para cada R\$ 1,00 a pagar',
            style: const TextStyle(
              fontSize: 11,
              color: GridColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (model.liquidezCorrente / 3.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: GridColors.divider.withOpacity(0.5),
              valueColor: AlwaysStoppedAnimation<Color>(
                liquidezSaudavel ? GridColors.secondary : GridColors.warning,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Margem Líquida:',
                  style: TextStyle(fontSize: 11, color: GridColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${model.margemLiquida.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: model.margemLiquida >= 0 ? GridColors.secondary : GridColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Card Termômetro FGV & Mercado
  Widget _buildTermometroFgvCard() {
    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Índices FGV & Mercado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GridColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GridColors.primarySoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'OFICIAL',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: GridColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildIndiceRow(
            nome: 'IGP-M (FGV)',
            subtitulo: 'Reajuste aluguel e planos',
            acumulado: '${model.igpmAcumulado12m.toStringAsFixed(2)}%',
            mensal: '+${model.igpmMensal.toStringAsFixed(2)}%',
            destaqueCor: GridColors.primary,
          ),
          const SizedBox(height: 6),
          _buildIndiceRow(
            nome: 'INCC (FGV)',
            subtitulo: 'Obras & equipamentos',
            acumulado: '${model.inccAcumulado12m.toStringAsFixed(2)}%',
            mensal: '+${model.inccMensal.toStringAsFixed(2)}%',
            destaqueCor: GridColors.secondary,
          ),
          const SizedBox(height: 6),
          _buildIndiceRow(
            nome: 'IPCA / Selic',
            subtitulo: 'Inflação e Renda Fixa',
            acumulado: '${model.ipcaAcumulado12m.toStringAsFixed(2)}%',
            mensal: '${model.selicAnual.toStringAsFixed(2)}% a.a.',
            destaqueCor: GridColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildIndiceRow({
    required String nome,
    required String subtitulo,
    required String acumulado,
    required String mensal,
    required Color destaqueCor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: GridColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: GridColors.divider.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: GridColors.textSecondary,
                  ),
                ),
                Text(
                  subtitulo,
                  style: const TextStyle(
                    fontSize: 9,
                    color: GridColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                acumulado,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: destaqueCor,
                ),
              ),
              Text(
                mensal,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: GridColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 5. Gráfico de Projeções Comparativas com Correção FGV
  Widget _buildGraficoProjecoesCard(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final proj = model.projecoes;

    if (proj.isEmpty) return const SizedBox.shrink();

    // Encontrar max Y para normalizar eixo
    double maxY = 1000;
    for (final p in proj) {
      maxY = math.max(maxY, math.max(p.receitaProjetada, p.metaAjustadaIgpm));
      maxY = math.max(maxY, p.despesasProjetadas);
    }
    maxY = (maxY * 1.15); // folga de 15%

    return _CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GridColors.secondarySoft,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: GridColors.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Projeção Financeira Semestral x Meta IGP-M (FGV)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GridColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Receitas projetadas comparadas com a meta ajustada pela inflação FGV e despesas',
                      style: const TextStyle(
                        fontSize: 11,
                        color: GridColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Legenda do gráfico
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendaItem(
                'Receita Projetada',
                GridColors.secondary,
                isDashed: false,
              ),
              _buildLegendaItem(
                'Meta Ajustada IGP-M (FGV)',
                GridColors.primary,
                isDashed: true,
              ),
              _buildLegendaItem(
                'Despesas Projetadas',
                GridColors.warning,
                isDashed: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Área do gráfico fl_chart
          SizedBox(
            height: isCompact ? 220 : 260,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: GridColors.divider.withOpacity(0.6),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 52,
                      interval: maxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        final valorK = (value / 1000.0).toStringAsFixed(0);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            'R\$ ${valorK}k',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: GridColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= proj.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            proj[idx].mes,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: GridColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Linha 1: Receita Projetada (Verde)
                  LineChartBarData(
                    spots: proj.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.receitaProjetada);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: GridColors.secondary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: GridColors.secondary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: GridColors.secondary.withOpacity(0.08),
                    ),
                  ),
                  // Linha 2: Meta Corrigida IGP-M FGV (Vermelho Abraço pontilhado)
                  LineChartBarData(
                    spots: proj.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.metaAjustadaIgpm);
                    }).toList(),
                    isCurved: true,
                    dashArray: [6, 4],
                    curveSmoothness: 0.35,
                    color: GridColors.primary,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                  // Linha 3: Despesas Projetadas (Laranja / Alerta)
                  LineChartBarData(
                    spots: proj.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.despesasProjetadas);
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: GridColors.warning,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: GridColors.warning,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        String label = '';
                        Color cor = spot.bar.color ?? Colors.black;
                        if (spot.barIndex == 0) label = 'Receita: ';
                        if (spot.barIndex == 1) label = 'Meta FGV: ';
                        if (spot.barIndex == 2) label = 'Despesa: ';
                        return LineTooltipItem(
                          '$label${currency.format(spot.y)}',
                          TextStyle(
                            color: cor,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(String label, Color cor, {required bool isDashed}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: GridColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 6. Card de Recomendações Estratégicas
  Widget _buildRecomendacoesCard(BuildContext context) {
    final igpm = model.igpmAcumulado12m;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.secondarySoft.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.secondary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: GridColors.secondary,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diretrizes Estratégicas para o Gestor',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: GridColors.secondaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Reajuste de Mensalidades: Com o IGP-M FGV acumulado em ${igpm.toStringAsFixed(2)}% nos últimos 12 meses, recomenda-se aplicar reposição inflacionária mínima de ${(igpm * 0.9).toStringAsFixed(1)}% a ${igpm.toStringAsFixed(1)}% nos contratos anuais renovados.\n'
                  '• Custo de Oportunidade: Com a Selic a ${model.selicAnual.toStringAsFixed(2)}% a.a., seu ROE operacional de ${model.roe.toStringAsFixed(1)}% a.a. '
                  '${model.alfaVsCdi >= 0 ? "gera retorno superior à taxa básica de juros (+${model.alfaVsCdi.toStringAsFixed(1)}% de alfa)." : "está abaixo do custo de oportunidade do capital. Focar em redução de custos operacionais."}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: GridColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;

  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: GridColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: GridColors.divider.withOpacity(0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

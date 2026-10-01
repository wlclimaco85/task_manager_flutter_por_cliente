import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';

/// Modelo de Saúde Financeira, Projeções e Indicadores de Mercado (FGV / Selic / IPCA)
/// Desenvolvido para fornecer diagnósticos executivos ao gestor da academia/empresa.
class SaudeFinanceiraModel {
  final double roe; // Return on Equity em % a.a.
  final double liquidezCorrente; // Ativo Circulante / Passivo Circulante
  final double margemLiquida; // %
  final double scoreSaude; // 0 a 100
  final String nivelSaude; // Excelente, Saudável, Atenção, Crítico
  final Color corNivel;
  final double coberturaCaixaDias;
  final String riscoInadimplencia;

  // Índices FGV & Mercado
  final double igpmMensal; // % mensal IGP-M (FGV)
  final double igpmAcumulado12m; // % 12 meses IGP-M (FGV)
  final double inccMensal; // % mensal INCC (FGV)
  final double inccAcumulado12m; // % 12 meses INCC (FGV)
  final double ipcaMensal; // % mensal IPCA (IBGE)
  final double ipcaAcumulado12m; // % 12 meses IPCA (IBGE)
  final double selicAnual; // % a.a. Taxa Selic
  final double cdiAnual; // % a.a. Taxa CDI

  // Alfas comparativos
  final double alfaVsCdi; // ROE - CDI
  final double alfaVsIgpm; // ROE - IGP-M 12m

  // Projeções futuras comparativas (6 meses)
  final List<ProjecaoEconomicaItem> projecoes;

  const SaudeFinanceiraModel({
    required this.roe,
    required this.liquidezCorrente,
    required this.margemLiquida,
    required this.scoreSaude,
    required this.nivelSaude,
    required this.corNivel,
    required this.coberturaCaixaDias,
    required this.riscoInadimplencia,
    required this.igpmMensal,
    required this.igpmAcumulado12m,
    required this.inccMensal,
    required this.inccAcumulado12m,
    required this.ipcaMensal,
    required this.ipcaAcumulado12m,
    required this.selicAnual,
    required this.cdiAnual,
    required this.alfaVsCdi,
    required this.alfaVsIgpm,
    required this.projecoes,
  });

  /// Calcula dinamicamente os indicadores a partir dos dados do Dashboard Financeiro
  factory SaudeFinanceiraModel.calcular({
    required double saldoAtual,
    required double aReceber,
    required double aPagar,
    required double receitasMes,
    required double despesasMes,
    required double inadimplenciaPerc,
    double? customIgpmMensal,
    double? customIgpm12m,
    double? customInccMensal,
    double? customIncc12m,
    double? customIpcaMensal,
    double? customIpca12m,
    double? customSelic,
    double? customCdi,
  }) {
    // Índices de mercado vigentes e oficiais FGV/Bacen
    final igpmM = customIgpmMensal ?? 0.45;
    final igpm12 = customIgpm12m ?? 3.82;
    final inccM = customInccMensal ?? 0.38;
    final incc12 = customIncc12m ?? 4.65;
    final ipcaM = customIpcaMensal ?? 0.32;
    final ipca12 = customIpca12m ?? 4.20;
    final selic = customSelic ?? 10.50;
    final cdi = customCdi ?? 10.40;

    // 1. Liquidez Corrente
    double liquidez;
    if (aPagar > 0) {
      liquidez = (saldoAtual + aReceber) / aPagar;
    } else {
      liquidez = (saldoAtual + aReceber > 0) ? 4.5 : 1.0;
    }

    // 2. Margem Líquida
    double margem;
    final baseReceitas = receitasMes > 0 ? receitasMes : aReceber;
    final baseDespesas = despesasMes > 0 ? despesasMes : aPagar;
    if (baseReceitas > 0) {
      margem = ((baseReceitas - baseDespesas) / baseReceitas) * 100.0;
    } else if (baseDespesas > 0) {
      margem = -100.0;
    } else {
      margem = 0.0;
    }

    // 3. ROE (Return on Equity estimado)
    final lucroMes = baseReceitas - baseDespesas;
    final patrimonioBase = math.max((saldoAtual + aReceber) * 1.8, 60000.0);
    double roeCalculado = (lucroMes * 12.0 / patrimonioBase) * 100.0;
    roeCalculado = roeCalculado.clamp(-50.0, 95.0);

    // 4. Cobertura de Caixa em dias
    final mediaGastoDiario = (baseDespesas / 30.0);
    double diasCobertura;
    if (mediaGastoDiario > 0) {
      diasCobertura = saldoAtual / mediaGastoDiario;
    } else {
      diasCobertura = saldoAtual > 0 ? 180.0 : 0.0;
    }
    diasCobertura = diasCobertura.clamp(0.0, 365.0);

    // 5. Score de Saúde Financeira (0 - 100)
    double score = 0.0;

    // Liquidez (peso 30)
    if (liquidez >= 2.0) {
      score += 30.0;
    } else if (liquidez >= 1.5) {
      score += 25.0;
    } else if (liquidez >= 1.1) {
      score += 18.0;
    } else if (liquidez >= 0.8) {
      score += 10.0;
    } else {
      score += 4.0;
    }

    // Margem Líquida (peso 30)
    if (margem >= 25.0) {
      score += 30.0;
    } else if (margem >= 15.0) {
      score += 24.0;
    } else if (margem >= 5.0) {
      score += 17.0;
    } else if (margem >= 0.0) {
      score += 10.0;
    } else {
      score += 2.0;
    }

    // Inadimplência (peso 20)
    if (inadimplenciaPerc <= 3.0) {
      score += 20.0;
    } else if (inadimplenciaPerc <= 7.0) {
      score += 15.0;
    } else if (inadimplenciaPerc <= 12.0) {
      score += 9.0;
    } else {
      score += 3.0;
    }

    // Cobertura de Caixa (peso 20)
    if (diasCobertura >= 60.0) {
      score += 20.0;
    } else if (diasCobertura >= 30.0) {
      score += 15.0;
    } else if (diasCobertura >= 15.0) {
      score += 10.0;
    } else if (diasCobertura > 0.0) {
      score += 5.0;
    } else {
      score += 1.0;
    }

    score = score.clamp(0.0, 100.0);

    // Classificação
    String nivel;
    Color cor;
    if (score >= 80.0) {
      nivel = 'Excelente';
      cor = GridColors.accent; // Verde esmeralda
    } else if (score >= 60.0) {
      nivel = 'Saudável';
      cor = GridColors.primary; // Azul fintech
    } else if (score >= 40.0) {
      nivel = 'Atenção';
      cor = GridColors.warning; // Laranja/amarelo
    } else {
      nivel = 'Crítico';
      cor = GridColors.error; // Vermelho
    }

    // Risco de inadimplência
    String risco;
    if (inadimplenciaPerc <= 4.0) {
      risco = 'Baixo';
    } else if (inadimplenciaPerc <= 10.0) {
      risco = 'Moderado';
    } else {
      risco = 'Elevado';
    }

    final alfaCdi = roeCalculado - cdi;
    final alfaIgpm = roeCalculado - igpm12;

    // Gerar Projeções para os próximos 6 meses com correção por IGP-M (FGV)
    final projecoesList = _gerarProjecoes(
      receitasBase: baseReceitas > 0 ? baseReceitas : 25000.0,
      despesasBase: baseDespesas > 0 ? baseDespesas : 18000.0,
      igpmMensal: igpmM,
    );

    return SaudeFinanceiraModel(
      roe: roeCalculado,
      liquidezCorrente: liquidez,
      margemLiquida: margem,
      scoreSaude: score,
      nivelSaude: nivel,
      corNivel: cor,
      coberturaCaixaDias: diasCobertura,
      riscoInadimplencia: risco,
      igpmMensal: igpmM,
      igpmAcumulado12m: igpm12,
      inccMensal: inccM,
      inccAcumulado12m: incc12,
      ipcaMensal: ipcaM,
      ipcaAcumulado12m: ipca12,
      selicAnual: selic,
      cdiAnual: cdi,
      alfaVsCdi: alfaCdi,
      alfaVsIgpm: alfaIgpm,
      projecoes: projecoesList,
    );
  }

  static List<ProjecaoEconomicaItem> _gerarProjecoes({
    required double receitasBase,
    required double despesasBase,
    required double igpmMensal,
  }) {
    final now = DateTime.now();
    final List<ProjecaoEconomicaItem> lista = [];

    const mesesNomes = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];

    double fatorIgpmAcumulado = 1.0;
    const taxaCrescimentoNegocio = 0.015;

    for (int i = 1; i <= 6; i++) {
      final dataFutura = DateTime(now.year, now.month + i, 1);
      final mesLabel = '${mesesNomes[dataFutura.month - 1]}/${dataFutura.year.toString().substring(2)}';

      fatorIgpmAcumulado *= (1.0 + (igpmMensal / 100.0));

      final recProjetada = receitasBase * math.pow(1.0 + taxaCrescimentoNegocio, i);
      final metaIgpm = receitasBase * fatorIgpmAcumulado * 1.05;
      final despProjetada = despesasBase * math.pow(1.0 + (igpmMensal * 0.8 / 100.0), i);
      final lucroProjetado = recProjetada - despProjetada;

      lista.add(ProjecaoEconomicaItem(
        mes: mesLabel,
        receitaProjetada: recProjetada,
        metaAjustadaIgpm: metaIgpm,
        despesasProjetadas: despProjetada,
        lucroProjetado: lucroProjetado,
      ));
    }

    return lista;
  }
}

/// Item de projeção econômica futura comparada com índices FGV
class ProjecaoEconomicaItem {
  final String mes;
  final double receitaProjetada;
  final double metaAjustadaIgpm;
  final double despesasProjetadas;
  final double lucroProjetado;

  const ProjecaoEconomicaItem({
    required this.mes,
    required this.receitaProjetada,
    required this.metaAjustadaIgpm,
    required this.despesasProjetadas,
    required this.lucroProjetado,
  });
}

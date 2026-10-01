import 'package:flutter/material.dart';
import '../../models/kpi_dashboard_model.dart';
import 'dashboard_state.dart';
import 'kpi_card.dart';

/// Widget responsivo comum dos 5 dashboards de área (Fase 171).
///
/// Decisão de arquitetura (Onda 0 do PLAN.md): este é um WIDGET puro, SEM
/// Scaffold/AppBar próprios — é embutido dentro do `body` de uma Screen-casca
/// leve por form factor (web/windows/mobile), nunca uma Screen completa.
/// Responsivo via LayoutBuilder: <600px → 1 coluna; 600-1200px → 2 colunas;
/// >=1200px → 3+ colunas.
class DashboardAreaScaffold extends StatelessWidget {
  final String titulo;
  final DashboardAreaState<List<KpiDashboardModel>> state;

  final DateTime? periodoInicio;
  final DateTime? periodoFim;
  final void Function(DateTime? periodoInicio, DateTime? periodoFim)?
      onPeriodoChanged;

  final void Function(
    DateTime? periodoInicio,
    DateTime? periodoFim,
    String? drillDownRota,
  )? onKpiTap;

  final VoidCallback? onRetry;

  const DashboardAreaScaffold({
    super.key,
    required this.titulo,
    required this.state,
    this.periodoInicio,
    this.periodoFim,
    this.onPeriodoChanged,
    this.onKpiTap,
    this.onRetry,
  });

  int _colunasPorLargura(double largura) {
    if (largura < 600) return 1;
    if (largura < 1200) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        switch (state.status) {
          case DashboardAreaStatus.loading:
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            );

          case DashboardAreaStatus.vazio:
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Nenhum dado encontrado'),
              ),
            );

          case DashboardAreaStatus.erro:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.mensagemErro ?? 'Erro ao carregar dados'),
                    const SizedBox(height: 12),
                    if (onRetry != null)
                      ElevatedButton(
                        onPressed: onRetry,
                        child: const Text('Tentar novamente'),
                      ),
                  ],
                ),
              ),
            );

          case DashboardAreaStatus.sucesso:
            final kpis = state.dados ?? const [];
            if (kpis.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Nenhum dado encontrado'),
                ),
              );
            }
            final colunas = _colunasPorLargura(constraints.maxWidth);
            return GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: colunas,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: kpis.length,
              itemBuilder: (context, index) {
                final kpi = kpis[index];
                return KpiCard(
                  kpi: kpi,
                  periodoInicio: periodoInicio,
                  periodoFim: periodoFim,
                  onTap: onKpiTap,
                );
              },
            );
        }
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../utils/api_links.dart';
import '../utils/grid_colors.dart';
import 'automacao_fiscal_screen.dart';
import 'importacao_sintegra_card.dart';
import 'importacao_sped_card.dart';

/// Tela dedicada de "Importação Fiscal / Automação Fiscal" (pedido do
/// usuário em 2026-09-10): antes vivia dentro de "Config. Sistema" (tela
/// admin-only, sem controle de permissão por empresa). Como o próprio
/// escritório precisa liberar isso pontualmente para uma empresa cliente
/// configurar seus próprios boletos/SPED/SINTEGRA, ela virou uma tela
/// própria no menu "Sistema", com `telaNome` dedicado
/// (`ImportacaoFiscalAutomacao`) na matriz de Permissões (Role x Tela),
/// em vez de herdar a permissão ampla de "Config. Sistema".
///
/// Duas abas:
/// - Importação Fiscal: upload manual avulso de SPED/SINTEGRA.
/// - Automação Fiscal: configuração da pasta raiz + intervalo de varredura
///   automática (boletos/speds/sintegra) e histórico de execuções.
class ImportacaoFiscalAutomacaoScreen extends StatefulWidget {
  const ImportacaoFiscalAutomacaoScreen({super.key});

  @override
  State<ImportacaoFiscalAutomacaoScreen> createState() =>
      _ImportacaoFiscalAutomacaoScreenState();
}

class _ImportacaoFiscalAutomacaoScreenState
    extends State<ImportacaoFiscalAutomacaoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController =
      TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        title: const Text('Importação Fiscal / Automação Fiscal'),
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          key: const Key('importacao_fiscal_automacao_tab_bar'),
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              text: 'Importação Fiscal',
              key: Key('importacao_fiscal_automacao_tab_manual'),
            ),
            Tab(
              text: 'Automação Fiscal',
              key: Key('importacao_fiscal_automacao_tab_automatica'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ImportacaoSintegraCard(baseUrl: ApiLinks.baseUrl),
                const SizedBox(height: 12),
                ImportacaoSpedCard(baseUrl: ApiLinks.baseUrl),
              ],
            ),
          ),
          const AutomacaoFiscalScreen(showAppBar: false),
        ],
      ),
    );
  }
}

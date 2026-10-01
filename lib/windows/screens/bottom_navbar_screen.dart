import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/custom_colors.dart';
import '../../features/agendamento/agendamento_module.dart';
import '../../widgets/login_empresa_acesso_aprovacao_screen.dart';
import '../../../models/alert_model.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';
import '../../../utils/security_matrix.dart';
import '../../services/alert_caller.dart';
import '../../../windows/screens/alimento_grid_screen.dart';
import '../../../windows/screens/aplicativo_screen.dart';
import '../../../auth_screens/login_screen.dart';
import '../../../windows/screens/chamado_grid_screen.dart';
import '../../../windows/screens/chatMessageListScreen.dart';
import '../../../windows/screens/comunicado_componente_screen.dart';
import '../../../windows/screens/integracoes_financeiras_screen.dart';
import '../../../windows/screens/conta_pagar_grid_screen.dart';
import '../../../windows/screens/conta_receber_grid_screen.dart';
import '../../../windows/screens/dashboard_financeiro_screen.dart';
import '../../../windows/screens/dashboard_mensalidade_screen.dart';
import '../../widgets/comercial/dashboard_comercial_mercadorias_screen.dart';
import '../../../widgets/boleto_importacao_lote_screen.dart';
import '../../../widgets/solicitacao_acesso_aprovacao_screen.dart';
import '../../../windows/screens/lancamento_financeiro_grid_screen.dart';
import '../../../windows/screens/dieta_grid_screen.dart';
import '../../../windows/screens/diretorio_grid_screen.dart';
import '../../../windows/screens/empresa_grid_screen.dart';
import '../../../windows/screens/exame_grid_screen.dart';
import '../../../windows/screens/exercicio_grid_screen.dart';
import '../../windows/screens/ged_arquivos_screen.dart';
import '../../../windows/screens/forma_pagamento_grid_screen.dart';
import '../../../windows/screens/grupo_muscular_grid_screen.dart';
import '../../../windows/screens/login_grid_screen.dart';
import '../../../windows/screens/medicamento_grid_screen.dart';
import '../../../windows/screens/mensalidade_grid_screen.dart';
import '../../../windows/screens/modalidade_grid_screen.dart';
import '../../../windows/screens/objetivo_grid_screen.dart';
import '../../../windows/screens/obrigacao_fiscal_grid_screen.dart';
import '../../../windows/screens/parceiro_grid_screen.dart';
import '../../../windows/screens/personal_grid_screen.dart';
import '../../../windows/screens/plano_grid_screen.dart';
import '../../../windows/screens/product_register_screen.dart';
import '../../../windows/screens/regime_grid_screen.dart';
import '../../../windows/screens/role_grid_screen.dart';
import '../../../windows/screens/setor_grid_screen.dart';
import '../../../windows/screens/suplemento_grid_screen.dart';
import 'documento_screen.dart';
import '../../../windows/screens/calendario_guias_grid_screen.dart';
import '../../../windows/screens/extrato_importacao_screen.dart';
import '../../../windows/screens/conciliacao_screen.dart';
import '../../../windows/screens/configuracoes_admin_screen.dart';
import '../../../windows/screens/cotacao_frete_grid_screen.dart';
import '../../../windows/screens/dividendo_grid_screen.dart';
import '../../../windows/screens/order_grid_screen.dart';
import '../../../windows/screens/pedido_grid_screen.dart';
import '../../../windows/screens/ticket_grid_screen.dart';
import '../../../windows/screens/alerta_aluno_grid_screen.dart';
import '../../../windows/screens/avaliacao_fisica_grid_screen.dart';
import '../../../windows/screens/academia_grid_screen.dart';
import '../../../windows/screens/conta_bancaria_grid_screen.dart';
import '../../../windows/screens/centro_custo_grid_screen.dart';
import '../../../windows/screens/categoria_financeira_grid_screen.dart';
import '../../../windows/screens/classificacao_grid_screen.dart';
import '../../../windows/screens/feriado_grid_screen.dart';
import '../../../windows/screens/nota_fiscal_entrada_grid_screen.dart';
import '../../../windows/screens/nota_fiscal_saida_grid_screen.dart';
import '../../../windows/screens/produto_grid_screen.dart';
import '../../../windows/screens/treino_grid_screen.dart';
import '../../../windows/screens/funcionario_grid_screen.dart';
import '../../windows/screens/kanban_chamados_screen.dart';
import '../../windows/screens/tela_editor_screen.dart';
import '../../../features/trading/trading_dashboard_screen.dart';
import '../../../features/trading/screens/sinais_screen.dart';
import '../../../features/trading/screens/oportunidades_screen.dart';
import '../../../features/trading/screens/backtest_screen.dart';
import '../../../features/trading/screens/trading_config_screen.dart';
import '../../../features/trading/services/backtest_repository.dart';
import '../../../features/trading/screens/carteira_screen.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import '../../../utils/menu_config.dart';
import '../../../widgets/app_sidebar.dart';
import '../../../widgets/internal_tab_strip.dart';
import '../../../models/open_tab.dart';
// Telas web reutilizadas no Windows
import '../../windows/screens/nfe_finalidade_grid_screen.dart';
import '../../windows/screens/nfe_serie_grid_screen.dart';
import '../../windows/screens/nfe_tipo_operacao_grid_screen.dart';
import '../../windows/screens/unidade_medida_grid_screen.dart';
import '../../windows/screens/catalago_produto_grid_screen.dart';
import '../../windows/screens/role_permissao_screen.dart';
import '../../windows/screens/tipo_parceiro_grid_screen.dart';
import '../../windows/screens/servico_contratado_grid_screen.dart';
import '../../windows/screens/modulo_servico_grid_screen.dart';
import '../../windows/screens/ponto_web_screen.dart';
import '../../windows/screens/ponto_solicitacao_screen.dart';
import '../../windows/screens/ponto_ajuste_screen.dart';
import '../../windows/screens/configuracoes_sistema_screen.dart';
import '../../windows/screens/system_test_screen.dart';
import '../../windows/screens/cadastro_empresa_wizard.dart';
import '../../windows/screens/alvara_grid_screen.dart';
import '../../windows/screens/fornecedor_grid_screen.dart';
import '../../windows/screens/nfe_import_screen.dart';
import '../../windows/screens/nfe_import_xml_screen.dart';
import '../../windows/screens/nfse_import_xml_screen.dart';
import '../../windows/screens/consulta_dfe_screen.dart';
import '../../windows/screens/manifestacao_destinatario_screen.dart';
import '../../windows/screens/nfce/pdv_screen.dart';
import '../../windows/screens/nfce/config_fiscal_screen.dart';
import '../../windows/screens/orcamento_grid_screen.dart';
import '../../windows/screens/pedido_venda_grid_screen.dart';
import '../../windows/screens/pedido_compra_grid_screen.dart';
import '../../windows/screens/nfse_screen.dart';
import '../../windows/screens/reserva_estoque_screen.dart';
import '../../windows/screens/deposito_screen.dart';
import '../../windows/screens/rateio_financeiro_screen.dart';
import '../../windows/screens/aprovacao_pagamento_screen.dart';
import '../../windows/screens/baixa_automatica_screen.dart';
import '../../windows/screens/cobranca_screen.dart';
import '../../windows/screens/renegociacao_screen.dart';
import '../../windows/screens/dre_screen.dart';
import '../../windows/screens/tabela_preco_screen.dart';
import '../../windows/screens/aprovacao_compra_screen.dart';
import '../../windows/screens/devolucao_grid_screen.dart';
import '../../windows/screens/cancelamento_cce_screen.dart';
import '../../windows/screens/regra_fiscal_screen.dart';
import '../../web/screens/contabil/conta_contabil_grid_screen.dart';
import '../../web/screens/contabil/lancamento_contabil_grid_screen.dart';
import '../../web/screens/contabil/balancete_screen.dart';
import '../../web/screens/contabil/fechamento_periodo_screen.dart';
import '../../web/screens/contabil/ai_dashboard_screen.dart';
import '../../web/screens/contabil/ai_assistente_screen.dart';
import '../../web/screens/cobranca_automatica_screen.dart';
import '../../web/screens/kanban_pagamentos_screen.dart';
import '../../web/screens/aprovacao_pagamentos_screen.dart';
import '../../web/screens/instagram_monitor_screen.dart';
import '../../widgets/chat/chat_kanban_screen.dart';
import './atividade_diaria_screen.dart';
import '../../features/diario_nutricional/diario_nutricional_screen.dart';
import './anamnese_screen.dart';
import './calendario_tributario_screen.dart';
import './comunicado_circular_screen.dart';
import './registro_carga_screen.dart';
import './frequencia_screen.dart';
import './home_saude_aluno_screen.dart';
import './historico_treino_screen.dart';
import './query_builder_window_screen.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../widgets/dp/dp_dashboard_screen.dart';
import '../../widgets/importacao_fiscal_automacao_screen.dart';
import '../../widgets/sessoes_screen.dart';
import 'certificado_empresa_screen.dart';
import '../../web/screens/nfce_grid_screen.dart';
import '../../web/screens/noticias_grid_screen.dart';
import '../../web/screens/cnab_remessa_screen.dart';
import '../../web/screens/nfse_serie_grid_screen.dart';
import '../../widgets/dashboard_executivo_screen.dart';

class WindowsBottomNavBarScreen extends StatefulWidget {
  const WindowsBottomNavBarScreen({super.key});

  @override
  State<WindowsBottomNavBarScreen> createState() =>
      _WindowsBottomNavBarScreenState();
}

class _WindowsBottomNavBarScreenState extends State<WindowsBottomNavBarScreen> {
  static const int _initialScreenIndex = 45; // Dashboard Executivo como tela inicial
  static const int _maxOpenTabs = 5;

  bool _isSidebarCollapsed = false;
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  OverlayEntry? notificationOverlay;
  bool _isLoading = true;
  late List<Widget> _screens;

  final List<OpenTab> _openTabs = [];
  int _activeTabIndex = 0;

  int get _selectedIndex => _openTabs.isEmpty
      ? _initialScreenIndex
      : _openTabs[_activeTabIndex].screenIndex;

  @override
  void initState() {
    super.initState();
    _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    await AuthUtility.isUserLoggedIn();
    if (!mounted) return;
    final userInfo = AuthUtility.userInfo?.data;
    final loginInfo = AuthUtility.userInfo?.login;
    if ((userInfo?.id == null) && (loginInfo?.id == null)) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() {
      _screens = _buildScreens(userInfo ?? loginInfo);
      _isLoading = false;
      _openInitialTab();
    });
    _startPeriodicFetch();
  }

  // ── Gerenciamento de abas internas ───────────────────────────────────────

  MenuItem? _menuItemForScreenIndex(int screenIndex) {
    final all = [
      ...MenuConfig.groups.expand((g) => g.items),
      ...MenuConfig.loose
    ];
    for (final item in all) {
      if (item.screenIndex == screenIndex) return item;
    }
    return null;
  }

  OpenTab _buildTab(int screenIndex) {
    final menuItem = _menuItemForScreenIndex(screenIndex);
    final widgetIndex = screenIndex.clamp(0, _screens.length - 1);
    return OpenTab(
      id: 'screen_$screenIndex',
      label: menuItem?.label ?? 'Tela $screenIndex',
      icon: menuItem?.icon ?? FontAwesomeIcons.fileLines,
      content: KeyedSubtree(
        key: ValueKey('screen_$screenIndex'),
        child: _screens[widgetIndex],
      ),
      screenIndex: screenIndex,
      openedAt: DateTime.now(),
    );
  }

  void _openInitialTab() {
    if (_openTabs.isEmpty) {
      _openTabs.add(_buildTab(_initialScreenIndex));
      _activeTabIndex = 0;
    }
  }

  void _activateOrOpenTab(MenuItem item) {
    if (item.screenIndex < 0) return;
    final screenIndex = item.screenIndex;

    final existingIndex =
        _openTabs.indexWhere((t) => t.screenIndex == screenIndex);
    if (existingIndex != -1) {
      setState(() => _activeTabIndex = existingIndex);
      return;
    }

    if (_openTabs.length < _maxOpenTabs) {
      setState(() {
        _openTabs.add(_buildTab(screenIndex));
        _activeTabIndex = _openTabs.length - 1;
      });
      return;
    }

    _autoCloseOldestTab(screenIndex);
  }

  void _openTabByScreenIndex(int screenIndex) {
    final item = _menuItemForScreenIndex(screenIndex);
    if (item != null) {
      _activateOrOpenTab(item);
    } else {
      final existingIndex =
          _openTabs.indexWhere((t) => t.screenIndex == screenIndex);
      if (existingIndex != -1) {
        setState(() => _activeTabIndex = existingIndex);
      } else if (_openTabs.length < _maxOpenTabs) {
        setState(() {
          _openTabs.add(_buildTab(screenIndex));
          _activeTabIndex = _openTabs.length - 1;
        });
      } else {
        _autoCloseOldestTab(screenIndex);
      }
    }
  }

  void _autoCloseOldestTab(int newScreenIndex) {
    setState(() {
      _openTabs.removeAt(0);
      _openTabs.add(_buildTab(newScreenIndex));
      _activeTabIndex = _openTabs.length - 1;
    });
  }

  void _closeTab(int index) {
    if (index < 0 || index >= _openTabs.length) return;
    setState(() {
      _openTabs.removeAt(index);
      if (_openTabs.isEmpty) {
        _openInitialTab();
        return;
      }
      if (_activeTabIndex == index) {
        // Foca a aba à esquerda; se não houver, a próxima à direita.
        _activeTabIndex = (index - 1).clamp(0, _openTabs.length - 1);
      } else if (_activeTabIndex > index) {
        _activeTabIndex -= 1;
      }
    });
  }

  /// Card #483: hasPermission real para o grid de Comunicado — antes vinha
  /// hardcoded como `(permission) => true`, mostrando os botões Novo/Excluir
  /// mesmo para logins sem permissão (ex.: cliente APP_ABRACO), o que gerava
  /// um popup de erro 403 confuso (o backend já bloqueia corretamente via
  /// @PreAuthorize em ComunicadosController). Usa a SecurityMatrix (mesma
  /// fonte de permissões do backend) para espelhar a regra no client.
  bool _comunicadoHasPermission(String permission) {
    final matrix = SecurityMatrix.current();
    switch (permission) {
      case 'create':
        return matrix.canInsert(AppScreen.comunicados);
      case 'edit':
        return matrix.canUpdate(AppScreen.comunicados);
      case 'delete':
      case 'deleteMultiple':
        return matrix.canDelete(AppScreen.comunicados);
      default:
        return matrix.canView(AppScreen.comunicados);
    }
  }

  bool _nfceHasPermission(String permission) {
    final matrix = SecurityMatrix.current();
    switch (permission) {
      case 'create':
        return matrix.canInsert(AppScreen.nfceGrid);
      case 'edit':
        return matrix.canUpdate(AppScreen.nfceGrid);
      case 'delete':
      case 'deleteMultiple':
        return matrix.canDelete(AppScreen.nfceGrid);
      default:
        return matrix.canView(AppScreen.nfceGrid);
    }
  }

  List<Widget> _buildScreens(dynamic userInfo) => [
        WindowsComunicadoGridComponentesScreen(
            hasPermission: _comunicadoHasPermission),
        WindowsChatListScreen(userName: userInfo?.email ?? 'Usuário'), // 1: Chat
        WindowsComunicadoGridComponentesScreen(
            hasPermission: _comunicadoHasPermission),
        WindowsAplicativoGridScreen(hasPermission: (permission) => true),
        WindowsLoginGridScreen(hasPermission: (permission) => true),
        WindowsChatListScreen(userName: userInfo.email ?? 'Usuário'),
        const WindowsProductRegisterScreen(),
        const WindowsProductRegisterScreen(),
        WindowsRegimeGridScreen(hasPermission: (perm) => true),
        WindowsAlimentoGridScreen(hasPermission: (perm) => true),
        WindowsDietaGridScreen(hasPermission: (perm) => true),
        WindowsEmpresaGridScreen(hasPermission: (perm) => true),
        WindowsExameGridScreen(hasPermission: (perm) => true),
        WindowsExercicioGridScreen(hasPermission: (perm) => true),
        WindowsGrupoMuscularGridScreen(hasPermission: (perm) => true),
        WindowsMedicamentoGridScreen(hasPermission: (perm) => true),
        WindowsMensalidadeGridScreen(hasPermission: (perm) => true),
        WindowsModalidadeGridScreen(hasPermission: (perm) => true),
        WindowsObjetivoGridScreen(hasPermission: (perm) => true),
        WindowsParceiroGridScreen(hasPermission: (perm) => true),
        WindowsPersonalGridScreen(hasPermission: (perm) => true),
        WindowsPlanoGridScreen(hasPermission: (perm) => true),
        WindowsRoleGridScreen(hasPermission: (perm) => true),
        WindowsSetorGridScreen(hasPermission: (perm) => true),
        WindowsSuplementoGridScreen(hasPermission: (perm) => true),
        WindowsContaPagarGridScreen(hasPermission: (perm) => true),
        WindowsContaReceberGridScreen(hasPermission: (perm) => true),
        WindowsChamadoGridScreen(hasPermission: (perm) => true),
        WindowsFormaPagamentoGridScreen(hasPermission: (perm) => true),
        WindowsDiretorioGridScreen(hasPermission: (perm) => true),
        GedArquivosScreen(), // 30: GED
        const WindowsCalendarScreen(),
        WindowsObrigacaoFiscalGridScreen(hasPermission: (perm) => true),
        WindowsLoginGridScreen(hasPermission: (perm) => true),
        // Novas telas
        WindowsCotacaoFreteGridScreen(hasPermission: (perm) => true),
        WindowsCalendarioGuiasGridScreen(hasPermission: (perm) => true),
        WindowsTicketGridScreen(hasPermission: (perm) => true),
        WindowsDividendoGridScreen(hasPermission: (perm) => true),
        WindowsOrderGridScreen(hasPermission: (perm) => true),
        WindowsPedidoGridScreen(hasPermission: (perm) => true),
        WindowsConfiguracoesAdminScreen(hasPermission: (perm) => true),
        WindowsAlertaAlunoGridScreen(hasPermission: (perm) => true),
        WindowsAvaliacaoFisicaGridScreen(hasPermission: (perm) => true),
        WindowsContaBancariaGridScreen(hasPermission: (perm) => true),
        WindowsClassificacaoGridScreen(hasPermission: (perm) => true),
        DashboardExecutivoScreen(
            onNavigateToScreen: _openTabByScreenIndex), // 45: Dashboard Executivo
        WindowsFeriadoGridScreen(hasPermission: (perm) => true),
        WindowsNotaFiscalEntradaGridScreen(hasPermission: (perm) => true),
        WindowsNotaFiscalSaidaGridScreen(hasPermission: (perm) => true),
        WindowsTreinoGridScreen(hasPermission: (perm) => true),
        WindowsFuncionarioGridScreen(hasPermission: (perm) => true),
        const KanbanChamadosScreen(),
        const TelaEditorScreen(),
        WindowsProdutoGridScreen(hasPermission: (perm) => true),
        // Telas adicionais (índices 54+)
        WindowsNfeFinalidadeGridScreen(hasPermission: (perm) => true), // 54
        WindowsNfeSerieGridScreen(hasPermission: (perm) => true), // 55
        WindowsNfeTipoOperacaoGridScreen(hasPermission: (perm) => true), // 56
        WindowsUnidadeMedidaGridScreen(hasPermission: (perm) => true), // 57
        WindowsCatalagoProdutoGridScreen(hasPermission: (perm) => true), // 58
        const RolePermissaoScreen(), // 59
        const WindowsPontoScreen(), // 60
        const WindowsPontoSolicitacaoScreen(), // 61
        const WindowsPontoAjusteScreen(), // 62
        const ConfiguracoesSistemaScreen(), // 63
        WindowsChatListScreen(
            userName: AuthUtility.userInfo?.data?.email ?? 'Usuário'), // 64
        const SystemTestScreen(), // 65
        const CadastroEmpresaWizard(), // 66
        WindowsTipoParceiroGridScreen(hasPermission: (perm) => true), // 67
        WindowsServicoContratadoGridScreen(hasPermission: (perm) => true), // 68
        WindowsModuloServicoGridScreen(hasPermission: (perm) => true), // 69
        WindowsAlvaraGridScreen(hasPermission: (perm) => true), // 70
        const NfeImportScreen(), // 71: NfeImportCSV
        const TradingDashboardScreen(), // 72: Painel Trading
        WindowsCentroCustoGridScreen(
            hasPermission: (perm) => true), // 73: CentroCusto
        WindowsCategoriaFinanceiraGridScreen(
            hasPermission: (perm) => true), // 74: CategoriasFinanceiras
        const SinaisScreen(), // 75: Sinais de Mercado
        const OportunidadesScreen(), // 76: Oportunidades
        const TradingDashboardScreen(initialTabIndex: 1), // 77: Watchlist
        const TradingDashboardScreen(
            initialTabIndex: 2), // 78: Alertas de Preço
        const TradingDashboardScreen(
            initialTabIndex: 3), // 79: Operações Assistidas
        const PdvScreen(), // 80: PDV NFC-e
        const ConfigFiscalScreen(), // 81: Config. Fiscal
        const SizedBox.shrink(), // 82
        const SizedBox.shrink(), // 83
        const SizedBox.shrink(), // 84: Ajuda (não disponível)
        BacktestScreen(
            repository: BacktestRepository(ApiLinks.baseUrl,
                headers: TenantContext.jsonHeaders)), // 85: Backtest
        const WindowsNfeImportXmlScreen(), // 86: NfeImportXml
        WebNoticiasGridScreen(hasPermission: (perm) => true), // 87: Noticias
        WindowsLancamentoFinanceiroGridScreen(
            hasPermission: (perm) => true), // 88: LancamentosFinanceiros
        const ExtratoImportacaoScreen(), // 89: ImportarExtrato
        const ConciliacaoScreen(), // 90: ConciliacaoBancaria
        const WindowsDashboardFinanceiroScreen(), // 91: DashboardFinanceiro
        const IntegracoesFinanceirasScreen(), // 92: IntegracoesFinanceiras
        WindowsFornecedorGridScreen(
            hasPermission: (perm) => true), // 93: Fornecedores
        const WindowsOrcamentoGridScreen(), // 94: Orçamentos
        WindowsPedidoVendaGridScreen(
            hasPermission: (perm) => true), // 95: Pedidos de Venda
        const WindowsPedidoCompraGridScreen(), // 96: Pedidos de Compra
        const ConsultaDfeScreen(), // 97: Consulta DF-e
        const ManifestacaoDestinatarioScreen(), // 98: Manifestação Destinatário
        const NfseScreen(), // 99: NFSe
        const ReservaEstoqueScreen(), // 100: ReservaEstoque
        const DepositoScreen(), // 101: Multi-depósito
        const RateioFinanceiroScreen(), // 102: Rateio Financeiro
        const AprovacaoPagamentoScreen(), // 103: Aprovação de Pagamentos
        const BaixaAutomaticaScreen(), // 104: Baixa Automática de Recebíveis
        const CobrancaScreen(), // 105: Inadimplência e Cobrança
        const RenegociacaoScreen(), // 106: Renegociação de Títulos
        const DreScreen(), // 107: DRE Gerencial
        TabelaPrecoScreen(
            hasPermission: (perm) => true), // 108: Tabela de Preços e Descontos
        const AprovacaoCompraScreen(), // 109: Aprovação de Compras
        const WindowsDevolucaoGridScreen(), // 110: Devoluções
        const CancelamentoCceScreen(), // 111: Cancelamento e CC-e
        RegraFiscalScreen(hasPermission: (perm) => true), // 112: Regras Fiscais
        WebContaContabilGridScreen(
            hasPermission: (perm) => true), // 113: Plano de Contas
        WebLancamentoContabilGridScreen(
            hasPermission: (perm) => true), // 114: Lançamentos
        const WebBalanceteScreen(), // 115: Balancete / Balanço
        const WebFechamentoPeriodoScreen(), // 116: Fechamento de Período
        const WebAiDashboardScreen(), // 117: Dashboard IA
        const WebAiAssistenteScreen(), // 118: Assistente IA
        const TradingConfigScreen(), // 119: Configuracao da Corretora
        const CarteiraScreen(), // 120: Minha Carteira
        const CobrancaAutomaticaScreen(), // 121: Cobranca Automatica
        const KanbanPagamentosScreen(), // 122: Kanban de Pagamentos
        const WebAprovacaoPagamentosScreen(), // 123: Aprovacao de Pagamentos
        WindowsAcademiaGridScreen(
            hasPermission: (perm) => true), // 124: Academia
        const SizedBox.shrink(), // 125: reservado AppAcademiaV003
        const SizedBox.shrink(), // 126: reservado AppAcademiaV003
        const SizedBox.shrink(), // 127
        const SizedBox.shrink(), // 128
        const SizedBox.shrink(), // 129
        const SizedBox.shrink(), // 130
        const SizedBox.shrink(), // 131
        const SizedBox.shrink(), // 132
        const SizedBox.shrink(), // 133
        const SizedBox.shrink(), // 134
        const SizedBox.shrink(), // 135
        const InstagramMonitorScreen(), // 136: Instagram Monitor
        const ChatKanbanScreen(), // 137: Kanban Chat
        const WindowsAtividadeDiariaScreen(), // 138: Atividade Diaria
        const DiarioNutricionalScreen(), // 139: Diario Nutricional
        const WindowsHomeSaudeAlunoScreen(), // 140: Home Saude do Aluno
        HistoricoTreinoScreen(
          alunoId: AuthUtility.userInfo?.data?.id ?? 0,
        ), // 141: Historico de Treinos
        const WebDashboardMensalidadeScreen(), // 142: Dashboard de Mensalidades
        const DpDashboardScreen(), // 143: Dashboard DP
        const SizedBox.shrink(), // 144: reservado
        const DashboardComercialMercadoriasScreen(), // 145: Dashboard Comercial
        const SizedBox.shrink(), // 146: Dashboard Fiscal (placeholder)
        const SizedBox.shrink(), // 147: reservado
        const BoletoImportacaoLoteScreen(), // 148: Importação Boletos Lote
        const SolicitacaoAcessoAprovacaoScreen(), // 149: Solicitações de Acesso
        const QueryBuilderWindowScreen(), // 150: Query Builder
        AnamneseScreen(
          alunoId: userInfo?.id ?? 0,
          nomeAluno: userName,
        ), // 151: Anamnese Digital
        const CalendarioTributarioScreen(), // 152: Calendario Tributario
        const ComunicadoCircularScreen(), // 153: Comunicados Circular
        const RegistroCargaScreen(
            sessionId: 0), // 154: Registro de Carga (placeholder sessionId)
        const FrequenciaScreen(), // 155: Frequencia Semanal
        DynamicGridDynamicScreen(telaNome: 'contrato', hasPermission: (p) => true), // 156: Contratos
        const SizedBox.shrink(), // 157: reservado
        DynamicGridDynamicScreen(telaNome: 'equipamento', hasPermission: (p) => true), // 158: Equipamentos
        DynamicGridDynamicScreen(telaNome: 'ordem_servico', hasPermission: (p) => true), // 159: Ordens de Serviço
        DynamicGridDynamicScreen(telaNome: 'plano_manutencao', hasPermission: (p) => true), // 160: Planos Manutenção
        DynamicGridDynamicScreen(telaNome: 'horimetro', hasPermission: (p) => true), // 161: Horímetro
        DynamicGridDynamicScreen(telaNome: 'historico_manutencao_screen', hasPermission: (p) => true), // 162: Histórico Manutenção
        DynamicGridDynamicScreen(telaNome: 'tecnico_manutencao_screen', hasPermission: (p) => true), // 163: Técnicos
        DynamicGridDynamicScreen(telaNome: 'sla_screen', hasPermission: (p) => true), // 164: SLA
        const SizedBox.shrink(), // 165: reservado
        DynamicGridDynamicScreen(telaNome: 'fila_atendimento_screen', hasPermission: (p) => true), // 166: Filas Atendimento
        DynamicGridDynamicScreen(telaNome: 'categoria_chamado_screen', hasPermission: (p) => true), // 167: Categorias Chamado
        DynamicGridDynamicScreen(telaNome: 'chamado_avaliacao_screen', hasPermission: (p) => true), // 168: Avaliações
        DynamicGridDynamicScreen(telaNome: 'projeto', hasPermission: (p) => true), // 169: Projetos
        const SizedBox.shrink(), // 170: reservado
        DynamicGridDynamicScreen(telaNome: 'projeto_etapa_screen', hasPermission: (p) => true), // 171: Etapas
        DynamicGridDynamicScreen(telaNome: 'projeto_recurso_screen', hasPermission: (p) => true), // 172: Recursos
        DynamicGridDynamicScreen(telaNome: 'projeto_apontamento_screen', hasPermission: (p) => true), // 173: Apontamentos
        DynamicGridDynamicScreen(telaNome: 'projeto_medicao_screen', hasPermission: (p) => true), // 174: Medições
        DynamicGridDynamicScreen(telaNome: 'cargo_recurso_screen', hasPermission: (p) => true), // 175: Cargos/Recursos
        DynamicGridDynamicScreen(telaNome: 'precificacao_screen', hasPermission: (p) => true), // 176: Precificações
        const SizedBox.shrink(), // 177: reservado
        DynamicGridDynamicScreen(telaNome: 'precificacao_custo_direto_screen', hasPermission: (p) => true), // 178: Custos Diretos
        DynamicGridDynamicScreen(telaNome: 'precificacao_mao_de_obra', hasPermission: (p) => true), // 179: Mão de Obra
        DynamicGridDynamicScreen(telaNome: 'precificacao_servico_screen', hasPermission: (p) => true), // 180: Serviços
        DynamicGridDynamicScreen(telaNome: 'precificacao_condicao_pagamento_screen', hasPermission: (p) => true), // 181: Condições Pagamento
        DynamicGridDynamicScreen(telaNome: 'proposta_comercial_screen', hasPermission: (p) => true), // 182: Propostas Comerciais
        const AgendamentoModuleScreen(), // 183: Agendamento NFe Recorrente
        const ImportacaoFiscalAutomacaoScreen(), // 184: Importação Fiscal / Automação Fiscal
        const LoginEmpresaAcessoAprovacaoScreen(), // 185: Permissões Multi-Empresa
        const SessoesScreen(), // 186: Sessões
        WebNfceGridScreen(hasPermission: _nfceHasPermission), // 187: NFC-e Cupons
        const MeuCertificadoDigitalScreen(), // 188: Certificado Digital
        // 189-203: ainda nao implementados/replicados no Windows (paridade
        // pendente com o menu Web, que ja vai at 203 -- fora do escopo deste
        // card). Placeholders pra manter o alinhamento posicional de
        // screenIndex (widgetIndex = screenIndex.clamp(0, _screens.length-1)
        // acima), sem o que o item 204 abaixo cairia no indice errado.
        const SizedBox.shrink(), // 189: reservado
        const SizedBox.shrink(), // 190: reservado
        const SizedBox.shrink(), // 191: reservado
        const SizedBox.shrink(), // 192: reservado
        const SizedBox.shrink(), // 193: reservado
        const SizedBox.shrink(), // 194: reservado
        const SizedBox.shrink(), // 195: reservado
        const SizedBox.shrink(), // 196: reservado
        const SizedBox.shrink(), // 197: reservado
        const SizedBox.shrink(), // 198: reservado
        const SizedBox.shrink(), // 199: reservado
        const SizedBox.shrink(), // 200: reservado
        const SizedBox.shrink(), // 201: reservado
        const CnabRemessaScreen(), // 202: Remessa EDI
        WebNfseSerieGridScreen(hasPermission: (perm) => true), // 203: NfseSerie
        const WindowsNfseImportXmlScreen(), // 204: NfseImportXml
      ];

  String get userName {
    final user = AuthUtility.userInfo?.data;
    if (user?.firstName != null && user?.lastName != null) {
      return '${user!.firstName!} ${user.lastName!}';
    } else if (user?.email != null) {
      return user!.email!;
    }
    return 'Usuário';
  }

  void _startPeriodicFetch() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) fetchAlerts();
    });
  }

  Future<void> fetchAlerts() async {
    try {
      final List<Alert> alertData =
          await AlertCaller().fetchNotificacoes(context);
      if (!mounted) return;
      setState(() {
        notifications = alertData;
        unreadAlerts = notifications.length;
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  Future<void> deleteNotification(Alert notificacao) async {
    await AlertCaller().marcarNotificacaoLida(notificacao);
    if (!mounted) return;
    closeNotificationDropdown();
    await fetchAlerts();
  }

  Future<void> deleteAllNotifications(BuildContext ctx, Offset pos) async {
    await AlertCaller().marcarTodasNotificacoesLidas();
    if (!mounted) return;
    closeNotificationDropdown();
    await fetchAlerts();
    if (mounted) showNotificationDropdown(ctx, pos);
  }

  void closeNotificationDropdown() {
    notificationOverlay?.remove();
    notificationOverlay = null;
  }

  void showNotificationDropdown(BuildContext context, Offset position) {
    if (notificationOverlay != null) {
      closeNotificationDropdown();
      return;
    }
    final overlay = Overlay.of(context);
    final double esquerda = _isSidebarCollapsed ? 70.0 : 250.0;
    final int totalNaoLidas = notifications.length;

    notificationOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: closeNotificationDropdown,
              behavior: HitTestBehavior.translucent,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: position.dy + 48,
            left: esquerda,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              shadowColor: GridColors.shadow,
              child: Container(
                width: 340,
                constraints: const BoxConstraints(maxHeight: 480),
                decoration: BoxDecoration(
                  color: GridColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GridColors.divider, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: GridColors.primary,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_outlined,
                              color: GridColors.textPrimary, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Notificações',
                              style: TextStyle(
                                color: GridColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (totalNaoLidas > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: GridColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$totalNaoLidas',
                                style: const TextStyle(
                                  color: GridColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: closeNotificationDropdown,
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.close,
                                  color: GridColors.textPrimaryMuted, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notifications.isNotEmpty)
                      InkWell(
                        onTap: () => deleteAllNotifications(context, position),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: const BoxDecoration(
                            color: GridColors.filterBackground,
                            border: Border(
                              bottom: BorderSide(
                                  color: GridColors.divider, width: 1),
                            ),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.done_all,
                                  size: 16, color: GridColors.secondary),
                              SizedBox(width: 6),
                              Text(
                                'Marcar todas como lidas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: GridColors.secondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    notifications.isNotEmpty
                        ? Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              itemCount: notifications.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: GridColors.divider,
                                  indent: 16,
                                  endIndent: 16),
                              itemBuilder: (_, i) {
                                final n = notifications[i];
                                final icone = _iconeParaTipo(n.status);
                                final corIcone = _corParaTipo(n.status);
                                final dataRel = _dataRelativa(n.data);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: corIcone.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(icone,
                                            size: 18, color: corIcone),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.texto,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: GridColors.textSecondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              dataRel,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: GridColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () => deleteNotification(n),
                                        borderRadius: BorderRadius.circular(20),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                              Icons.check_circle_outline,
                                              size: 18,
                                              color: GridColors.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.notifications_off_outlined,
                                    size: 48, color: GridColors.divider),
                                SizedBox(height: 12),
                                Text(
                                  'Sem notificações',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: GridColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Você está em dia!',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: GridColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(notificationOverlay!);
  }

  IconData _iconeParaTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'ALVARA':
      case 'ALVARA_VENCENDO':
        return Icons.assignment_late_outlined;
      case 'CONTA_PAGAR':
      case 'CP_VENCIDA':
      case 'CP_A_VENCER':
        return Icons.payments_outlined;
      case 'CONTA_RECEBER':
      case 'CR_VENCIDA':
      case 'CR_A_VENCER':
        return Icons.request_quote_outlined;
      case 'CHAMADO':
        return Icons.support_agent_outlined;
      case 'CHAT':
      case 'MENSAGEM':
        return Icons.chat_bubble_outline;
      case 'GED':
        return Icons.attach_file_outlined;
      case 'COMUNICADO':
        return Icons.campaign_outlined;
      default:
        return Icons.circle_notifications_outlined;
    }
  }

  Color _corParaTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'ALVARA':
      case 'ALVARA_VENCENDO':
        return GridColors.warning;
      case 'CONTA_PAGAR':
      case 'CP_VENCIDA':
        return GridColors.error;
      case 'CP_A_VENCER':
        return GridColors.warning;
      case 'CONTA_RECEBER':
      case 'CR_VENCIDA':
        return GridColors.error;
      case 'CR_A_VENCER':
        return GridColors.warning;
      case 'CHAMADO':
        return GridColors.primary;
      case 'CHAT':
      case 'MENSAGEM':
        return GridColors.secondary;
      case 'GED':
        return GridColors.info;
      case 'COMUNICADO':
        return GridColors.accent;
      default:
        return GridColors.neutral;
    }
  }

  String _dataRelativa(String? isoData) {
    if (isoData == null || isoData.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoData).toLocal();
      final agora = DateTime.now();
      final diff = agora.difference(dt);
      if (diff.inMinutes < 1) return 'agora mesmo';
      if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'há ${diff.inHours}h';
      if (diff.inDays == 1) return 'ontem';
      if (diff.inDays < 7) return 'há ${diff.inDays} dias';
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return isoData ?? '';
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Deseja realmente sair?",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CustomColors().getTextColor())),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Não",
                  style: TextStyle(color: CustomColors().getTextColor()))),
          TextButton(
            onPressed: () {
              AuthUtility.clearUserInfo();
              AuthUtility.setUserInfo(
                  LoginModel(data: null, token: '', status: ''));
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const WindowsBottomNavBarScreen()),
                (route) => false,
              );
            },
            child: Text("Sim",
                style: TextStyle(color: CustomColors().getTextColor())),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    notificationOverlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Row(
        children: [
          // Sidebar — novo com submenus, busca e favoritos
          AppSidebar(
            selectedIndex: _selectedIndex,
            onSelect: _activateOrOpenTab,
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () =>
                setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
            unreadAlerts: unreadAlerts,
            onNotificationTap: () {
              final box = context.findRenderObject() as RenderBox;
              showNotificationDropdown(context, box.localToGlobal(Offset.zero));
            },
            onLogout: _handleLogout,
            userName: userName,
            userEmail: AuthUtility.userInfo?.data?.codDadosPessoal?.email ??
                AuthUtility.userInfo?.login?.email ??
                '',
          ),
          // Main Content: faixa de abas internas + IndexedStack preservando estado
          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: Column(
                children: [
                  InternalTabStrip(
                    tabs: _openTabs,
                    activeIndex: _activeTabIndex,
                    onActivate: (i) => setState(() => _activeTabIndex = i),
                    onClose: _closeTab,
                    isCompact: false,
                  ),
                  Expanded(
                    child: IndexedStack(
                      index: _activeTabIndex,
                      children: _openTabs.map((t) => t.content).toList(),
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
}

class SidebarItem {
  final IconData icon;
  final String label;
  SidebarItem({required this.icon, required this.label});
}

Uint8List showBase64Image(base64String) {
  if (base64String != null && base64String.toString().trim().isNotEmpty) {
    final image = "data:image/png;base64,$base64String";
    final data = Uri.parse(image).data;
    return data!.contentAsBytes();
  }
  return Uint8List(0);
}

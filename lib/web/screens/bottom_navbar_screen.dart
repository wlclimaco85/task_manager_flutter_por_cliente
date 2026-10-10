import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'cnab_remessa_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../constants/custom_colors.dart';
import '../../features/agendamento/agendamento_module.dart';
import '../../widgets/login_empresa_acesso_aprovacao_screen.dart';
import '../../../models/alert_model.dart';
import '../../../models/auth_utility.dart';
import '../../../models/login_model.dart';
import '../../../utils/security_matrix.dart';
import '../../services/alert_caller.dart';
import './aplicativo_screen.dart';
import '../../../auth_screens/login_screen.dart';
import './chamado_grid_screen.dart';
import './alimento_grid_screen.dart';
import './comunicado_componente_screen.dart';
import './comunicado_circular_screen.dart';
import './dieta_grid_screen.dart';
import './empresa_grid_screen.dart';
import './exame_grid_screen.dart';
import './exercicio_grid_screen.dart';
import './grupo_muscular_grid_screen.dart';
import './medicamento_grid_screen.dart';
import './mensalidade_grid_screen.dart';
import './modalidade_grid_screen.dart';
import './objetivo_grid_screen.dart';
import './parceiro_grid_screen.dart';
import './tipo_parceiro_grid_screen.dart';
import './servico_contratado_grid_screen.dart';
import './modulo_servico_grid_screen.dart';
import './regime_grid_screen.dart';
import './noticias_grid_screen.dart';
import './conta_pagar_grid_screen.dart';
import './dashboard_financeiro_screen.dart';
import './dashboard_mensalidade_screen.dart';
import '../../widgets/comercial/dashboard_comercial_mercadorias_screen.dart';
import '../../widgets/boleto_importacao_lote_screen.dart';
import '../../widgets/solicitacao_acesso_aprovacao_screen.dart';
import './conta_receber_grid_screen.dart';
import './lancamento_financeiro_grid_screen.dart';
import './diretorio_grid_screen.dart';
import './ged_arquivos_screen.dart';
import './forma_pagamento_grid_screen.dart';
import './login_grid_screen.dart';
import './obrigacao_fiscal_grid_screen.dart';
import './personal_grid_screen.dart';
import './plano_grid_screen.dart';
import './product_register_screen.dart';
import './role_grid_screen.dart';
import './role_permissao_screen.dart';
import './setor_grid_screen.dart';
import './suplemento_grid_screen.dart';
import 'documento_screen.dart';
import './calendario_guias_grid_screen.dart';
import './configuracoes_admin_screen.dart';
import './cotacao_frete_grid_screen.dart';
import './dividendo_grid_screen.dart';
import './order_grid_screen.dart';
import './pedido_grid_screen.dart';
import './ticket_grid_screen.dart';
import './alerta_aluno_grid_screen.dart';
import './avaliacao_fisica_grid_screen.dart';
import './academia_grid_screen.dart';
import './conta_bancaria_grid_screen.dart';
import './centro_custo_grid_screen.dart';
import './categoria_financeira_grid_screen.dart';
import './classificacao_grid_screen.dart';
import './feriado_grid_screen.dart';
import './treino_grid_screen.dart';
import './system_test_screen.dart';
import './cadastro_empresa_wizard.dart';
import './funcionario_grid_screen.dart';
import './kanban_chamados_screen.dart';
import './tela_editor_screen.dart';
import './produto_grid_screen.dart';
import './unidade_medida_grid_screen.dart';
import './catalago_produto_grid_screen.dart';
import './nfe_finalidade_grid_screen.dart';
import './nfe_serie_grid_screen.dart';
import './nfse_serie_grid_screen.dart';
import './nfe_tipo_operacao_grid_screen.dart';
import './nfe_grid_screen.dart';
import './nfce_grid_screen.dart';
import './nfe_import_screen.dart';
import './nfe_import_xml_screen.dart';
import './nfse_import_xml_screen.dart';
import './consulta_dfe_screen.dart';
import './manifestacao_destinatario_screen.dart';
import './ponto_web_screen.dart';
import './ponto_solicitacao_screen.dart';
import './ponto_ajuste_screen.dart';
import './configuracoes_sistema_screen.dart';
import './chatMessageListScreen.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import '../../features/trading/screens/sinais_screen.dart';
import '../../features/trading/screens/oportunidades_screen.dart';
import '../../features/trading/screens/backtest_screen.dart';
import '../../features/trading/screens/trading_config_screen.dart';
import '../../features/trading/services/backtest_repository.dart';
import '../../features/trading/screens/carteira_screen.dart';
import '../../utils/api_links.dart';
import '../../utils/tenant_context.dart';
import '../../utils/menu_config.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/internal_tab_strip.dart';
import '../../models/open_tab.dart';
import './alvara_grid_screen.dart';
import './fornecedor_grid_screen.dart';
import './nfce/pdv_screen.dart';
import './nfce/config_fiscal_screen.dart';
import '../../windows/screens/reserva_estoque_screen.dart';
import '../../windows/screens/deposito_screen.dart';
import '../../windows/screens/renegociacao_screen.dart';
import '../../windows/screens/devolucao_grid_screen.dart';
import '../../windows/screens/rateio_financeiro_screen.dart';
import '../../windows/screens/aprovacao_pagamento_screen.dart';
import '../../windows/screens/baixa_automatica_screen.dart';
import '../../windows/screens/cobranca_screen.dart';
import './aprovacao_compra_screen.dart';
import './dre_screen.dart';
import './tabela_preco_screen.dart';
import './extrato_importacao_screen.dart';
import './conciliacao_screen.dart';
import './integracoes_financeiras_screen.dart';
import './orcamento_grid_screen.dart';
import './pedido_venda_grid_screen.dart';
import './pedido_compra_grid_screen.dart';
import '../../windows/screens/nfse_screen.dart';
import '../../windows/screens/query_builder_window_screen.dart';
import './cancelamento_cce_screen.dart';
import 'contabil/conta_contabil_grid_screen.dart';
import 'contabil/lancamento_contabil_grid_screen.dart';
import 'contabil/balancete_screen.dart';
import 'contabil/fechamento_periodo_screen.dart';
import 'contabil/ai_dashboard_screen.dart';
import 'contabil/ai_assistente_screen.dart';
import './cobranca_automatica_screen.dart';
import './kanban_pagamentos_screen.dart';
import './aprovacao_pagamentos_screen.dart';
import './instagram_monitor_screen.dart';
import '../../widgets/chat/chat_kanban_screen.dart';
import './atividade_diaria_screen.dart';
import '../../features/diario_nutricional/diario_nutricional_screen.dart';
import './anamnese_screen.dart';
import './calendario_tributario_screen.dart';
import './registro_carga_screen.dart';
import './frequencia_screen.dart';
import './home_saude_aluno_screen.dart';
import './historico_treino_screen.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../widgets/dp/dp_dashboard_screen.dart';
import '../../widgets/importacao_fiscal_automacao_screen.dart';
import '../../widgets/sessoes_screen.dart';
import 'certificado_empresa_screen.dart';
import './regra_fiscal_screen.dart';
import '../../widgets/dashboard_executivo_screen.dart';

class WebBottomNavBarScreen extends StatefulWidget {
  final int initialIndex;
  const WebBottomNavBarScreen({super.key, this.initialIndex = 45});

  @override
  State<WebBottomNavBarScreen> createState() => _WebBottomNavBarScreenState();
}

class _WebBottomNavBarScreenState extends State<WebBottomNavBarScreen> {
  static const int _maxOpenTabs = 5;

  late int _initialScreenIndex;
  bool _isSidebarCollapsed = false;
  int unreadAlerts = 0;
  List<Alert> notifications = [];
  Timer? _periodicTimer;
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
    _initialScreenIndex = widget.initialIndex;
    _loadUserAndInit();
  }

  Future<void> _loadUserAndInit() async {
    await AuthUtility.isUserLoggedIn();
    if (!mounted) return;
    final hasData = AuthUtility.userInfo?.data?.id != null;
    final hasLogin = AuthUtility.userInfo?.login?.id != null;
    if (!hasData && !hasLogin) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }
    setState(() {
      _screens = _buildScreensList();
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
        _activeTabIndex = (index - 1).clamp(0, _openTabs.length - 1);
      } else if (_activeTabIndex > index) {
        _activeTabIndex -= 1;
      }
    });
  }

  String get userName {
    final user = AuthUtility.userInfo?.data;
    final login = AuthUtility.userInfo?.login;
    if (user?.firstName != null && user?.lastName != null) {
      return '${user!.firstName!} ${user.lastName!}';
    } else if (user?.email != null) {
      return user!.email!;
    } else if (login?.nome != null) {
      return login!.nome!;
    } else if (login?.email != null) {
      return login!.email!;
    }
    return 'Usuário';
  }

  /// Card #483: hasPermission real para o grid de Comunicado — antes vinha
  /// hardcoded como `(p) => true`, mostrando os botões Novo/Excluir mesmo
  /// para logins sem permissão (ex.: cliente APP_ABRACO), o que gerava um
  /// popup de erro 403 confuso (o backend já bloqueia corretamente via
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

  /// hasPermission real para o grid de NFC-e Cupons — controla botões de ação
  /// dentro da tela com base na SecurityMatrix (espelha as permissões do backend).
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

  List<Widget> _buildScreensList() {
    final userInfo = AuthUtility.userInfo?.data;
    final loginInfo = AuthUtility.userInfo?.login;
    final isLoggedIn = (userInfo?.id != null) || (loginInfo?.id != null);
    if (!isLoggedIn) return [const LoginScreen()];
    return [
      WebComunicadoGridComponentesScreen(
          hasPermission: _comunicadoHasPermission), // 0:  Comunicados
      WebChatListScreen(
          userName: AuthUtility.userInfo?.login?.email ?? 'Usuário'), // 1: Chat
      WebComunicadoGridComponentesScreen(
          hasPermission: _comunicadoHasPermission), // 2:  ComunicadoComp
      WebAplicativoGridScreen(hasPermission: (p) => true), // 3:  Aplicativo
      WebLoginGridScreen(hasPermission: (p) => true), // 4:  Logins
      WebChatListScreen(
          userName:
              AuthUtility.userInfo?.login?.email ?? 'Usuário'), // 5: ChatList
      const WebProductRegisterScreen(), // 6:  placeholder
      const WebProductRegisterScreen(), // 7:  placeholder
      WebRegimeGridScreen(hasPermission: (p) => true), // 8:  Regime
      WebAlimentoGridScreen(hasPermission: (p) => true), // 9:  Alimentos
      WebDietaGridScreen(hasPermission: (p) => true), // 10: Dietas
      WebEmpresaGridScreen(hasPermission: (p) => true), // 11: Empresas
      WebExameGridScreen(hasPermission: (p) => true), // 12: Exames
      WebExercicioGridScreen(hasPermission: (p) => true), // 13: Exercícios
      WebGrupoMuscularGridScreen(
          hasPermission: (p) => true), // 14: GruposMusculares
      WebMedicamentoGridScreen(hasPermission: (p) => true), // 15: Medicamentos
      WebMensalidadeGridScreen(hasPermission: (p) => true), // 16: Mensalidades
      WebModalidadeGridScreen(hasPermission: (p) => true), // 17: Modalidades
      WebObjetivoGridScreen(hasPermission: (p) => true), // 18: Objetivos
      WebParceiroGridScreen(hasPermission: (p) => true), // 19: Parceiros
      WebPersonalGridScreen(hasPermission: (p) => true), // 20: Personais
      WebPlanoGridScreen(hasPermission: (p) => true), // 21: Planos
      WebRoleGridScreen(hasPermission: (p) => true), // 22: Roles
      WebSetorGridScreen(hasPermission: (p) => true), // 23: Setores
      WebSuplementoGridScreen(hasPermission: (p) => true), // 24: Suplementos
      WebContaPagarGridScreen(hasPermission: (p) => true), // 25: ContasPagar
      WebContaReceberGridScreen(
          hasPermission: (p) => true), // 26: ContasReceber
      WebChamadoGridScreen(hasPermission: (p) => true), // 27: Chamados
      WebFormaPagamentoGridScreen(
          hasPermission: (p) => true), // 28: FormasPagamento
      WebDiretorioGridScreen(hasPermission: (p) => true), // 29: Diretorios
      const GedArquivosScreen(), // 30: GED — Arquivos
      const WebCalendarScreen(useLightHeader: true), // 31: Calendario — sem header duplicado (pedido usuario 2026-09-10)
      WebObrigacaoFiscalGridScreen(
          hasPermission: (p) => true), // 32: ObrigacoesFiscais
      WebLoginGridScreen(hasPermission: (p) => true), // 33: Logins(dup)
      WebCotacaoFreteGridScreen(hasPermission: (p) => true), // 34: CotacaoFrete
      WebCalendarioGuiasGridScreen(
          hasPermission: (p) => true), // 35: CalendarioGuias
      WebTicketGridScreen(hasPermission: (p) => true), // 36: Tickets
      WebDividendoGridScreen(hasPermission: (p) => true), // 37: Dividendos
      WebOrderGridScreen(hasPermission: (p) => true), // 38: Ordens
      WebPedidoGridScreen(hasPermission: (p) => true), // 39: Pedidos
      WebConfiguracoesAdminScreen(
          hasPermission: (p) => true), // 40: ConfigAdmin
      WebAlertaAlunoGridScreen(hasPermission: (p) => true), // 41: AlertaAluno
      WebAvaliacaoFisicaGridScreen(
          hasPermission: (p) => true), // 42: AvaliacaoFisica
      WebContaBancariaGridScreen(
          hasPermission: (p) => true), // 43: ContaBancaria
      WebClassificacaoGridScreen(
          hasPermission: (p) => true), // 44: Classificacao
      DashboardExecutivoScreen(
          onNavigateToScreen: _openTabByScreenIndex), // 45: Dashboard Executivo
      WebFeriadoGridScreen(hasPermission: (p) => true), // 46: Feriados
      const WebNfeGridScreen(entrada: true), // 47: NFeEntrada
      const WebNfeGridScreen(entrada: false), // 48: NFeSaida
      WebTreinoGridScreen(hasPermission: (p) => true), // 49: Treino
      WebFuncionarioGridScreen(hasPermission: (p) => true), // 50: Funcionarios
      const KanbanChamadosScreen(), // 51: Kanban
      const TelaEditorScreen(), // 52: EditorTelas
      WebProdutoGridScreen(hasPermission: (p) => true), // 53: Produtos
      WebNfeFinalidadeGridScreen(
          hasPermission: (p) => true), // 54: NfeFinalidade
      WebNfeSerieGridScreen(hasPermission: (p) => true), // 55: NfeSerie
      WebNfeTipoOperacaoGridScreen(
          hasPermission: (p) => true), // 56: NfeTipoOperacao
      WebUnidadeMedidaGridScreen(
          hasPermission: (p) => true), // 57: UnidadeMedida
      WebCatalagoProdutoGridScreen(
          hasPermission: (p) => true), // 58: CatalagoProduto
      const RolePermissaoScreen(), // 59: Permissoes
      const WebPontoScreen(), // 60: Ponto
      const WebPontoSolicitacaoScreen(), // 61: SolicitarAjuste
      const WebPontoAjusteScreen(), // 62: AjustePonto
      const ConfiguracoesSistemaScreen(), // 63: ConfigSistema
      WebChatListScreen(
          userName:
              AuthUtility.userInfo?.login?.email ?? 'Usuário'), // 64: Chat
      const SystemTestScreen(), // 65: Teste
      const CadastroEmpresaWizard(), // 66: CadastroEmpresa
      WebTipoParceiroGridScreen(hasPermission: (p) => true), // 67: TipoParceiro
      WebServicoContratadoGridScreen(
          hasPermission: (p) => true), // 68: ServicoContratado
      WebModuloServicoGridScreen(
          hasPermission: (p) => true), // 69: ModuloServico
      WebAlvaraGridScreen(hasPermission: (p) => true), // 70: Alvarás
      const NfeImportScreen(), // 71: NfeImportCSV
      const TradingDashboardScreen(), // 72: Painel Trading
      WebCentroCustoGridScreen(hasPermission: (p) => true), // 73: CentroCusto
      WebCategoriaFinanceiraGridScreen(
          hasPermission: (p) => true), // 74: CategoriasFinanceiras
      const SinaisScreen(), // 75: Sinais de Mercado
      const OportunidadesScreen(), // 76: Oportunidades
      const TradingDashboardScreen(initialTabIndex: 1), // 77: Watchlist
      const TradingDashboardScreen(initialTabIndex: 2), // 78: Alertas de Preço
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
      const WebNfeImportXmlScreen(), // 86: NfeImportXml
      WebNoticiasGridScreen(hasPermission: (p) => true), // 87: Noticias
      WebLancamentoFinanceiroGridScreen(
          hasPermission: (p) => true), // 88: LancamentosFinanceiros
      const ExtratoImportacaoScreen(), // 89: ImportarExtrato
      const WebConciliacaoScreen(), // 90: ConciliacaoBancaria
      const WebDashboardFinanceiroScreen(), // 91: DashboardFinanceiro
      const WebIntegracoesFinanceirasScreen(), // 92: IntegracoesFinanceiras
      WebFornecedorGridScreen(hasPermission: (p) => true), // 93: Fornecedores
      const WebOrcamentoGridScreen(), // 94: Orçamentos
      const WebPedidoVendaGridScreen(), // 95: Pedidos de Venda
      const WebPedidoCompraGridScreen(), // 96: Pedidos de Compra
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
      const WebDreScreen(), // 107: DRE Gerencial
      WebTabelaPrecoScreen(hasPermission: (p) => true), // 108: Tabela de Preços e Descontos
      const WebAprovacaoCompraScreen(), // 109: Aprovação de Compras
      const WindowsDevolucaoGridScreen(), // 110: Devoluções
      const CancelamentoCceScreen(), // 111: Cancelamento e CC-e
      RegraFiscalScreen(hasPermission: (p) => true), // 112: RegraFiscal
      WebContaContabilGridScreen(
          hasPermission: (p) => true), // 113: Plano de Contas
      WebLancamentoContabilGridScreen(
          hasPermission: (p) => true), // 114: Lançamentos
      const WebBalanceteScreen(), // 115: Balancete / Balanço
      const WebFechamentoPeriodoScreen(), // 116: Fechamento de Período
      const WebAiDashboardScreen(), // 117: Dashboard IA
      const WebAiAssistenteScreen(), // 118: Assistente IA
      const TradingConfigScreen(), // 119: Configuracao da Corretora
      const CarteiraScreen(), // 120: Minha Carteira
      const CobrancaAutomaticaScreen(), // 121: Cobranca Automatica
      const KanbanPagamentosScreen(), // 122: Kanban de Pagamentos
      const WebAprovacaoPagamentosScreen(), // 123: Aprovacao de Pagamentos
      WebAcademiaGridScreen(hasPermission: (p) => true), // 124: Academia
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
      const WebAtividadeDiariaScreen(), // 138: Atividade Diaria
      const DiarioNutricionalScreen(), // 139: Diario Nutricional
      const WebHomeSaudeAlunoScreen(), // 140: Home Saude do Aluno
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
        alunoId: AuthUtility.userInfo?.data?.id ?? 0,
        nomeAluno: userName,
      ), // 151: Anamnese Digital
      const CalendarioTributarioScreen(), // 152: Calendario Tributario
      const ComunicadoCircularScreen(), // 153: Comunicados Circular
      const RegistroCargaScreen(sessionId: 0), // 154: Registro de Carga (placeholder sessionId)
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
      DynamicGridDynamicScreen(telaNome: 'projeto_etapa', hasPermission: (p) => true), // 171: Etapas
      DynamicGridDynamicScreen(telaNome: 'projeto_recurso', hasPermission: (p) => true), // 172: Recursos
      DynamicGridDynamicScreen(telaNome: 'projeto_apontamento', hasPermission: (p) => true), // 173: Apontamentos
      DynamicGridDynamicScreen(telaNome: 'projeto_medicao', hasPermission: (p) => true), // 174: Medições
      DynamicGridDynamicScreen(telaNome: 'cargo_recurso', hasPermission: (p) => true), // 175: Cargos/Recursos
      DynamicGridDynamicScreen(telaNome: 'precificacao', hasPermission: (p) => true), // 176: Precificações
      const SizedBox.shrink(), // 177: reservado
      DynamicGridDynamicScreen(telaNome: 'custo_direto', hasPermission: (p) => true), // 178: Custos Diretos
      DynamicGridDynamicScreen(telaNome: 'mao_de_obra', hasPermission: (p) => true), // 179: Mão de Obra
      DynamicGridDynamicScreen(telaNome: 'precificacao_servico', hasPermission: (p) => true), // 180: Serviços
      DynamicGridDynamicScreen(telaNome: 'condicao_pagamento', hasPermission: (p) => true), // 181: Condições Pagamento
      DynamicGridDynamicScreen(telaNome: 'proposta_comercial', hasPermission: (p) => true), // 182: Propostas Comerciais
      const AgendamentoModuleScreen(), // 183: Agendamento NFe Recorrente
      const ImportacaoFiscalAutomacaoScreen(), // 184: Importação Fiscal / Automação Fiscal
      const LoginEmpresaAcessoAprovacaoScreen(), // 185: Permissões Multi-Empresa
      const SessoesScreen(), // 186: Sessões
      WebNfceGridScreen(hasPermission: _nfceHasPermission), // 187: NFC-e Cupons
      const MeuCertificadoDigitalScreen(), // 188: Certificado Digital
      const SizedBox.shrink(), // 189
      const SizedBox.shrink(), // 190
      const SizedBox.shrink(), // 191
      const SizedBox.shrink(), // 192
      const SizedBox.shrink(), // 193
      const SizedBox.shrink(), // 194
      const SizedBox.shrink(), // 195
      const SizedBox.shrink(), // 196
      const SizedBox.shrink(), // 197
      const SizedBox.shrink(), // 198
      const SizedBox.shrink(), // 199
      const SizedBox.shrink(), // 200
      const SizedBox.shrink(), // 201
      CnabRemessaScreen(), // 202: Remessa EDI
      WebNfseSerieGridScreen(hasPermission: (p) => true), // 203: NfseSerie
      const WebNfseImportXmlScreen(), // 204: NfseImportXml
    ];
  }

  void _startPeriodicFetch() {
    _periodicTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => fetchAlerts());
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
    try {
      notificationOverlay?.remove();
    } catch (_) {}
    notificationOverlay = null;
  }

  void showNotificationDropdown(BuildContext context, Offset position) {
    if (notificationOverlay != null) {
      closeNotificationDropdown();
      return;
    }
    final overlay = Overlay.of(context);
    final double esquerda = _isSidebarCollapsed ? 70.0 : 260.0;
    final int totalNaoLidas = notifications.length;

    notificationOverlay = OverlayEntry(
      builder: (ctx) {
        try {
          return Stack(
            children: [
              // Camada transparente para fechar ao clicar fora
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
                        // ── Cabeçalho ──────────────────────────────────────────
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

                    // ── Ação "Marcar todas como lidas" ─────────────────────
                    if (notifications.isNotEmpty)
                      InkWell(
                        onTap: () =>
                            deleteAllNotifications(context, position),
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

                    // ── Lista ou estado vazio ───────────────────────────────
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
                                final dataRelativa =
                                    _dataRelativa(n.data);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Ícone de tipo
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
                                      // Texto e data
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
                                              dataRelativa,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: GridColors.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Botão marcar lida
                                      InkWell(
                                        onTap: () => deleteNotification(n),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(Icons.check_circle_outline,
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
                        : Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
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
      );
        } catch (_) {
          closeNotificationDropdown();
          rethrow;
        }
      },
    );
    overlay.insert(notificationOverlay!);
  }

  /// Retorna ícone adequado ao tipo/status da notificação.
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

  /// Retorna cor associada ao tipo/status da notificação.
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

  /// Converte uma data ISO 8601 em texto relativo legível (ex: "há 2 dias").
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
      return isoData;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Deseja realmente sair?',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: CustomColors().getTextColor())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Não',
                style: TextStyle(color: CustomColors().getTextColor())),
          ),
          TextButton(
            onPressed: () {
              AuthUtility.clearUserInfo();
              AuthUtility.setUserInfo(
                  LoginModel(data: null, token: '', status: ''));
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const WebBottomNavBarScreen()),
                (route) => false,
              );
            },
            child: Text('Sim',
                style: TextStyle(color: CustomColors().getTextColor())),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    closeNotificationDropdown();
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
          // Sidebar com submenus, busca e favoritos
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
          // Conteúdo principal: faixa de abas internas + IndexedStack preservando estado
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
                    isCompact: true,
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

Uint8List showBase64Image(dynamic base64String) {
  if (base64String != null && base64String.toString().trim().isNotEmpty) {
    final image = 'data:image/png;base64,$base64String';
    final data = Uri.parse(image).data;
    return data!.contentAsBytes();
  }
  return Uint8List(0);
}

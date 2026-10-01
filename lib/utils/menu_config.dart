import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Definição de um item de menu
class MenuItem {
  final String id;
  final String label;
  final FaIconData icon;
  final int screenIndex; // índice na lista _screens (-1 = não implementado)

  const MenuItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.screenIndex,
  });
}

/// Grupo de menu (submenu expansível)
class MenuGroup {
  final String id;
  final String label;
  final FaIconData icon;
  final List<MenuItem> items;

  const MenuGroup({
    required this.id,
    required this.label,
    required this.icon,
    required this.items,
  });
}

/// Índices _buildScreens (Web e Windows):
/// 0:Comunicado  1:Chat  2:ComunicadoComp  3:Aplicativo  4:Logins  5:ChatList
/// 6,7:ProductRegister  8:Regime  9:Alimentos  10:Dietas  11:Empresas
/// 12:Exames  13:Exercícios  14:GruposMusculares  15:Medicamentos
/// 16:Mensalidades  17:Modalidades  18:Objetivos  19:Parceiros  20:Personais
/// 21:Planos  22:Roles  23:Setores  24:Suplementos  25:ContasPagar
/// 26:ContasReceber  27:Chamados  28:FormasPagamento  29:Diretorios
/// 30:Arquivos  31:Calendario  32:ObrigacoesFiscais  33:[ORPHAN-era Logins dup]
/// 34:CotacaoFrete  35:CalendarioGuias  36:Tickets  37:Dividendos
/// 38:Ordens  39:Pedidos  40:ConfigAdmin  41:AlertaAluno  42:AvaliacaoFisica
/// 43:ContaBancaria  44:Classificacao  45:Dashboard  46:Feriados
/// 47:NFeEntrada  48:NFeSaida  49:Treino  50:Funcionarios  51:Kanban
/// 52:EditorTelas  53:Produtos
/// 54:NfeFinalidade  55:NfeSerie  56:NfeTipoOperacao  57:UnidadeMedida
/// 58:CatalagoProduto  59:Permissoes  60:Ponto  61:SolicitarAjuste
/// 62:AjustePonto  63:ConfigSistema  64:Chat  65:Teste  66:CadastroEmpresa
/// 67:TipoParceiro  68:ServicoContratado  69:ModuloServico  70:Alvaras  71:NfeImportCSV
/// 72:TradingPainel  73:CRM/Funil  74:AutomacaoFiscal
/// 75:Sinais  76:Oportunidades  77:Watchlist  78:AlertasPreco  79:OperacoesAssistidas
/// 80:PdvNfce  81:ConfigFiscal  84:AjudaTelas  85:Backtest
/// 86:NfeImportXml 87:Noticias 88:LancamentosFinanceiros
/// 89:ImportarExtrato
/// 90:ConciliacaoBancaria
/// 92:IntegracoesFinanceiras
/// 93:Fornecedores
/// 94:Orcamentos
/// 95:PedidosVenda
/// 96:PedidosCompra
/// 97:ConsultaDfe
/// 98:ManifestacaoDestinatario
/// 99:Nfse
/// 100:ReservaEstoque
/// 101:Multi-deposito
/// 102:RateioFinanceiro
/// 103:AprovacaoPagamentos
/// 104:BaixaAutomaticaRecebiveis
/// 105:Cobranca
/// 106:Renegociacao
/// 107:Dre
/// 108:TabelaPreco
/// 109:AprovacaoCompra
/// 110:Devolucoes
/// 111:CancelamentoCCe
/// 112:RegraFiscal (Windows only)
/// 113:ContaContabil 114:LancamentoContabil 115:Balancete
/// 116:FechamentoPeriodo 117:AiDashboard 118:AiAssistente 119:TradingCorretora
/// 124:Academia
/// 136:InstagramMonitor
/// 204:NfseImportXml

class MenuConfig {
  MenuConfig._();

  // Ordem por uso: Comercial (inclui o que e' comum a NF-e/NFS-e/NFC-e,
  // como Série e Dashboard Fiscal) -> NF-e -> NFS-e -> NFC-e -> Financeiro
  // -> Pessoal -> Suporte/Comunicação -> Contábil -> Produtos ->
  // Configurações -> Sistema -> grupos só-escritório (Sistema, App
  // Academia, Bolsa de Valores). Cada documento fiscal tem seu proprio
  // menu dedicado desde 2026-09-18 (pedido do usuario: o menu antigo
  // "Fiscal / NFC-e" misturava NF-e/NFS-e/NFC-e, dificultando achar telas).
  static const List<MenuGroup> groups = [
    MenuGroup(
      id: 'comercial',
      label: 'Comercial',
      icon: FontAwesomeIcons.briefcase,
      items: [
        // Série e Dashboard fiscal ficam aqui por serem conceitos COMUNS
        // entre NF-e/NFS-e/NFC-e (cada documento tem sua propria numeracao/
        // série, mas a gestao de série e o dashboard consolidado sao vistos
        // como administrativos, nao exclusivos de um tipo de documento --
        // pedido explicito do usuario pra desembaralhar o menu Comercial,
        // que antes misturava NF-e/NFS-e/NFC-e junto com vendas/compras).
        MenuItem(
            id: 'nfe_serie',
            label: 'NF-e Série',
            icon: FontAwesomeIcons.hashtag,
            screenIndex: 55),
        MenuItem(
            id: 'nfse_serie',
            label: 'Séries NFS-e',
            icon: FontAwesomeIcons.hashtag,
            screenIndex: 203),
        MenuItem(
            id: 'dashboard_fiscal',
            label: 'Dashboard Fiscal',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 146),
        MenuItem(
            id: 'planos',
            label: 'Planos',
            icon: FontAwesomeIcons.listCheck,
            screenIndex: 21),
        MenuItem(
            id: 'tipo_parceiro',
            label: 'Tipo de Parceiro',
            icon: FontAwesomeIcons.tags,
            screenIndex: 67),
        MenuItem(
            id: 'servicos_contratados',
            label: 'Serviços Contratados',
            icon: FontAwesomeIcons.fileContract,
            screenIndex: 68),
        MenuItem(
            id: 'modulos_servicos',
            label: 'Módulos/Serviços',
            icon: FontAwesomeIcons.cubes,
            screenIndex: 69),
        MenuItem(
            id: 'orcamentos',
            label: 'Orçamentos',
            icon: FontAwesomeIcons.fileInvoice,
            screenIndex: 94),
        MenuItem(
            id: 'pedidos_venda',
            label: 'Pedidos de Venda',
            icon: FontAwesomeIcons.cartShopping,
            screenIndex: 95),
        MenuItem(
            id: 'pedidos_compra',
            label: 'Pedidos de Compra',
            icon: FontAwesomeIcons.cartPlus,
            screenIndex: 96),
        MenuItem(
            id: 'aprovacao_compra',
            label: 'Aprovação de Compras',
            icon: FontAwesomeIcons.checkDouble,
            screenIndex: 109),
        MenuItem(
            id: 'tabela_preco',
            label: 'Tabela de Preços',
            icon: FontAwesomeIcons.tags,
            screenIndex: 108),
        MenuItem(
            id: 'devolucoes',
            label: 'Devoluções',
            icon: FontAwesomeIcons.arrowRotateLeft,
            screenIndex: 110),
        MenuItem(
            id: 'dashboard_comercial',
            label: 'Dashboard Comercial',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 145),
      ],
    ),
    // Pedido explicito do usuario (2026-09-18): o menu "Comercial"/"Fiscal
    // NFC-e" misturava NF-e, NFS-e e NFC-e juntos, confuso pra achar cada
    // tela -- agora cada documento fiscal tem seu proprio menu dedicado.
    // O que e' comum aos tres (série, dashboard) ficou no grupo Comercial
    // acima.
    MenuGroup(
      id: 'nfe',
      label: 'NF-e',
      icon: FontAwesomeIcons.fileInvoiceDollar,
      items: [
        MenuItem(
            id: 'nfe_entrada',
            label: 'NF-e Entrada',
            icon: FontAwesomeIcons.fileImport,
            screenIndex: 47),
        MenuItem(
            id: 'nfe_saida',
            label: 'NF-e Saída',
            icon: FontAwesomeIcons.fileExport,
            screenIndex: 48),
        MenuItem(
            id: 'nfe_finalidade',
            label: 'NF-e Finalidade',
            icon: FontAwesomeIcons.fileCircleCheck,
            screenIndex: 54),
        MenuItem(
            id: 'nfe_tipo_operacao',
            label: 'NF-e Tipo Operação',
            icon: FontAwesomeIcons.arrowsLeftRight,
            screenIndex: 56),
        MenuItem(
            id: 'nfe_import_csv',
            label: 'Importar NF-e CSV',
            icon: FontAwesomeIcons.fileCsv,
            screenIndex: 71),
        MenuItem(
            id: 'nfe_import_xml',
            label: 'Importar XML NF-e',
            icon: FontAwesomeIcons.fileCode,
            screenIndex: 86),
        MenuItem(
            id: 'consulta_dfe',
            label: 'Consulta DF-e',
            icon: FontAwesomeIcons.magnifyingGlass,
            screenIndex: 97),
        MenuItem(
            id: 'manifestacao_destinatario',
            label: 'Manifestação Destinatário',
            icon: FontAwesomeIcons.fileCircleCheck,
            screenIndex: 98),
        MenuItem(
            id: 'cancelamento_cce',
            label: 'Cancelamento e CC-e',
            icon: FontAwesomeIcons.filePen,
            screenIndex: 111),
        MenuItem(
            id: 'agendamento_nfe',
            label: 'Agendar NFe Recorrente',
            icon: FontAwesomeIcons.calendarPlus,
            screenIndex: 183),
      ],
    ),
    MenuGroup(
      id: 'nfse',
      label: 'NFS-e',
      icon: FontAwesomeIcons.fileInvoice,
      items: [
        MenuItem(
            id: 'nfse',
            label: 'NFSe',
            icon: FontAwesomeIcons.fileInvoice,
            screenIndex: 99),
        MenuItem(
            id: 'nfse_import_xml',
            label: 'Importar XML NFS-e',
            icon: FontAwesomeIcons.fileCode,
            screenIndex: 204),
      ],
    ),
    MenuGroup(
      id: 'nfce',
      label: 'NFC-e',
      icon: FontAwesomeIcons.cashRegister,
      items: [
        MenuItem(
            id: 'pdv_nfce',
            label: 'PDV / NFC-e',
            icon: FontAwesomeIcons.cashRegister,
            screenIndex: 80),
        MenuItem(
            id: 'nfce_grid',
            label: 'NFC-e (Cupons)',
            icon: FontAwesomeIcons.receipt,
            screenIndex: 187),
        MenuItem(
            id: 'config_fiscal',
            label: 'Config. Fiscal',
            icon: FontAwesomeIcons.gear,
            screenIndex: 81),
      ],
    ),
    MenuGroup(
      id: 'financeiro',
      label: 'Financeiro',
      icon: FontAwesomeIcons.moneyBillTrendUp,
      items: [
        MenuItem(
            id: 'calendario',
            label: 'Calendário',
            icon: FontAwesomeIcons.calendar,
            screenIndex: 31),
        MenuItem(
            id: 'calendario_guias',
            label: 'Calendário de Guias',
            icon: FontAwesomeIcons.calendarDays,
            screenIndex: 35),
        MenuItem(
            id: 'conta_bancaria',
            label: 'Conta Bancária',
            icon: FontAwesomeIcons.buildingColumns,
            screenIndex: 43),
        MenuItem(
            id: 'contas_pagar',
            label: 'Contas a Pagar',
            icon: FontAwesomeIcons.moneyBill,
            screenIndex: 25),
        MenuItem(
            id: 'contas_receber',
            label: 'Contas a Receber',
            icon: FontAwesomeIcons.moneyCheckDollar,
            screenIndex: 26),
        MenuItem(
            id: 'formas_pagamento',
            label: 'Formas de Pagamento',
            icon: FontAwesomeIcons.creditCard,
            screenIndex: 28),
        MenuItem(
            id: 'centros_custo',
            label: 'Centros de Custo',
            icon: FontAwesomeIcons.sitemap,
            screenIndex: 73),
        MenuItem(
            id: 'categorias_financeiras',
            label: 'Categorias Financeiras',
            icon: FontAwesomeIcons.tags,
            screenIndex: 74),
        MenuItem(
            id: 'dashboard_financeiro',
            label: 'Dashboard Financeiro',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 91),
        MenuItem(
            id: 'dashMensalidadeArea',
            label: 'Dashboard de Mensalidades',
            icon: FontAwesomeIcons.chartColumn,
            screenIndex: 147),
        MenuItem(
            id: 'lancamentos_financeiros',
            label: 'Lançamentos Financeiros',
            icon: FontAwesomeIcons.moneyBillTransfer,
            screenIndex: 88),
        MenuItem(
            id: 'importar_extrato',
            label: 'Importar Extrato',
            icon: FontAwesomeIcons.fileImport,
            screenIndex: 89),
        MenuItem(
            id: 'importar_boletos_lote',
            label: 'Importar Boletos (Lote)',
            icon: FontAwesomeIcons.filePdf,
            screenIndex: 148),
        MenuItem(
            id: 'conciliacao_bancaria',
            label: 'Conciliação Bancária',
            icon: FontAwesomeIcons.arrowsRotate,
            screenIndex: 90),
        MenuItem(
            id: 'integracoes_financeiras',
            label: 'Integrações',
            icon: FontAwesomeIcons.gears,
            screenIndex: 92),
        MenuItem(
            id: 'rateio_financeiro',
            label: 'Rateio Financeiro',
            icon: FontAwesomeIcons.scaleBalanced,
            screenIndex: 102),
        MenuItem(
            id: 'baixa_automatica',
            label: 'Baixa Automática de Recebíveis',
            icon: FontAwesomeIcons.moneyBillWave,
            screenIndex: 104),
        MenuItem(
            id: 'cobranca',
            label: 'Inadimplência e Cobrança',
            icon: FontAwesomeIcons.exclamationTriangle,
            screenIndex: 105),
        MenuItem(
            id: 'renegociacao',
            label: 'Renegociação de Títulos',
            icon: FontAwesomeIcons.handshake,
            screenIndex: 106),
        MenuItem(
            id: 'dre_gerencial',
            label: 'DRE Gerencial',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            screenIndex: 107),
                MenuItem(
            id: 'cnab_remessa',
            label: 'Envio EDI (Remessa)',
            icon: FontAwesomeIcons.fileExport,
            screenIndex: 202),
        MenuItem(
            id: 'cobranca_automatica',
            label: 'Cobrança Automática',
            icon: FontAwesomeIcons.moneyBillWave,
            screenIndex: 121),
        MenuItem(
            id: 'kanban_pagamentos',
            label: 'Kanban de Pagamentos',
            icon: FontAwesomeIcons.tableColumns,
            screenIndex: 122),
        MenuItem(
            id: 'aprovacao_pagamentos_web',
            label: 'Aprovação de Pagamentos',
            icon: FontAwesomeIcons.checkDouble,
            screenIndex: 123),
      ],
    ),
    MenuGroup(
      id: 'depto_pessoal',
      label: 'Depto. Pessoal',
      icon: FontAwesomeIcons.idCard,
      items: [
        MenuItem(
            id: 'ajuste_ponto',
            label: 'Ajuste de Ponto',
            icon: FontAwesomeIcons.clockRotateLeft,
            screenIndex: 62),
        MenuItem(
            id: 'feriados',
            label: 'Feriados',
            icon: FontAwesomeIcons.umbrellaBeach,
            screenIndex: 46),
        MenuItem(
            id: 'funcionario',
            label: 'Funcionários',
            icon: FontAwesomeIcons.idCard,
            screenIndex: 50),
        MenuItem(
            id: 'ponto',
            label: 'Ponto',
            icon: FontAwesomeIcons.clock,
            screenIndex: 60),
        MenuItem(
            id: 'setores',
            label: 'Setores',
            icon: FontAwesomeIcons.sitemap,
            screenIndex: 23),
        MenuItem(
            id: 'solicitar_ajuste',
            label: 'Solicitar Ajuste Ponto',
            icon: FontAwesomeIcons.penToSquare,
            screenIndex: 61),
        MenuItem(
            id: 'dashboard_dp',
            label: 'Dashboard DP',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 143),
        MenuItem(
            id: 'relatorio_dp_rh',
            label: 'Relatórios DP/RH',
            icon: FontAwesomeIcons.filePdf,
            screenIndex: 144),
      ],
    ),
    MenuGroup(
      id: 'suporte_comunicacao',
      label: 'Suporte / Comunicação',
      icon: FontAwesomeIcons.comments,
      items: [
        MenuItem(
            id: 'chat',
            label: 'Chat',
            icon: FontAwesomeIcons.comments,
            screenIndex: 64),
        MenuItem(
            id: 'comunicados',
            label: 'Comunicados',
            icon: FontAwesomeIcons.newspaper,
            screenIndex: 0),
        MenuItem(
            id: 'alertas',
            label: 'Alertas',
            icon: FontAwesomeIcons.bell,
            screenIndex: 41),
        MenuItem(
            id: 'chamados',
            label: 'Chamados',
            icon: FontAwesomeIcons.ticketSimple,
            screenIndex: 27),
        MenuItem(
            id: 'diretorios',
            label: 'Diretórios',
            icon: FontAwesomeIcons.folderTree,
            screenIndex: 29),
        MenuItem(
            id: 'ged',
            label: 'GED',
            icon: FontAwesomeIcons.folderOpen,
            screenIndex: 30),
        MenuItem(
            id: 'noticias',
            label: 'Notícias',
            icon: FontAwesomeIcons.newspaper,
            screenIndex: 87),
        MenuItem(
            id: 'kanban',
            label: 'Kanban',
            icon: FontAwesomeIcons.trello,
            screenIndex: 51),
        MenuItem(
            id: 'kanban_chat',
            label: 'Kanban Chat',
            icon: FontAwesomeIcons.trello,
            screenIndex: 137),
        MenuItem(
            id: 'instagram_monitor',
            label: 'Instagram Monitor',
            icon: FontAwesomeIcons.instagram,
            screenIndex: 136),
      ],
    ),
    MenuGroup(
      id: 'contabil',
      label: 'Contábil',
      icon: FontAwesomeIcons.fileInvoiceDollar,
      items: [
        MenuItem(
            id: 'conta_contabil',
            label: 'Plano de Contas',
            icon: FontAwesomeIcons.tableList,
            screenIndex: 113),
        MenuItem(
            id: 'lancamento_contabil',
            label: 'Lançamentos',
            icon: FontAwesomeIcons.penToSquare,
            screenIndex: 114),
        MenuItem(
            id: 'balancete',
            label: 'Balancete / Balanço',
            icon: FontAwesomeIcons.scaleBalanced,
            screenIndex: 115),
        MenuItem(
            id: 'fechamento_periodo',
            label: 'Fechamento de Período',
            icon: FontAwesomeIcons.lock,
            screenIndex: 116),
        MenuItem(
            id: 'ai_dashboard',
            label: 'Dashboard IA',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 117),
        MenuItem(
            id: 'ai_assistente',
            label: 'Assistente IA',
            icon: FontAwesomeIcons.robot,
            screenIndex: 118),
      ],
    ),
    MenuGroup(
      id: 'produtos',
      label: 'Produtos',
      icon: FontAwesomeIcons.box,
      items: [
        MenuItem(
            id: 'catalogo_produto',
            label: 'Catálogo Produto',
            icon: FontAwesomeIcons.boxOpen,
            screenIndex: 58),
        MenuItem(
            id: 'produtos',
            label: 'Produtos',
            icon: FontAwesomeIcons.box,
            screenIndex: 53),
        MenuItem(
            id: 'unidade_medida',
            label: 'Unidade de Medida',
            icon: FontAwesomeIcons.rulerHorizontal,
            screenIndex: 57),
        MenuItem(
            id: 'reserva_estoque',
            label: 'Reserva de Estoque',
            icon: FontAwesomeIcons.boxesStacked,
            screenIndex: 100),
        MenuItem(
            id: 'multi_deposito',
            label: 'Multi-depósito',
            icon: FontAwesomeIcons.warehouse,
            screenIndex: 101),
      ],
    ),
    MenuGroup(
      id: 'configuracoes',
      label: 'Configurações',
      icon: FontAwesomeIcons.sliders,
      items: [
        MenuItem(
            id: 'logins',
            label: 'Logins',
            icon: FontAwesomeIcons.userLock,
            screenIndex: 4),
        MenuItem(
            id: 'solicitacoes_acesso',
            label: 'Solicitações de Acesso',
            icon: FontAwesomeIcons.userCheck,
            screenIndex: 149),
        MenuItem(
            id: 'permissoes_multi_empresa',
            label: 'Permissões Multi-Empresa',
            icon: FontAwesomeIcons.buildingUser,
            screenIndex: 185),
        MenuItem(
            id: 'obrigacoes_fiscais',
            label: 'Obrigações Fiscais',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            screenIndex: 32),
        MenuItem(
            id: 'regime_tributario',
            label: 'Regime Tributário',
            icon: FontAwesomeIcons.taxi,
            screenIndex: 8),
        MenuItem(
            id: 'roles',
            label: 'Roles',
            icon: FontAwesomeIcons.userShield,
            screenIndex: 22),
        MenuItem(
            id: 'alvaras',
            label: 'Alvarás',
            icon: FontAwesomeIcons.stamp,
            screenIndex: 70),
      ],
    ),
    MenuGroup(
      id: 'sistema',
      label: 'Sistema',
      icon: FontAwesomeIcons.gear,
      items: [
        MenuItem(
            id: 'aplicativo',
            label: 'Aplicativo',
            icon: FontAwesomeIcons.appStore,
            screenIndex: 3),
        MenuItem(
            id: 'cadastro_empresa',
            label: 'Cadastro Empresa',
            icon: FontAwesomeIcons.building,
            screenIndex: 66),
        MenuItem(
            id: 'config_admin',
            label: 'Configurações Admin',
            icon: FontAwesomeIcons.gear,
            screenIndex: 40),
        MenuItem(
            id: 'config_sistema',
            label: 'Config. Sistema',
            icon: FontAwesomeIcons.screwdriverWrench,
            screenIndex: 63),
        MenuItem(
            id: 'editor_telas',
            label: 'Editor de Telas',
            icon: FontAwesomeIcons.tableColumns,
            screenIndex: 52),
        MenuItem(
            id: 'importacao_fiscal_automacao',
            label: 'Importação Fiscal / Automação',
            icon: FontAwesomeIcons.folderTree,
            screenIndex: 184),
        MenuItem(
            id: 'certificado_digital',
            label: 'Certificado Digital',
            icon: FontAwesomeIcons.certificate,
            screenIndex: 188),
        MenuItem(
            id: 'empresas',
            label: 'Empresas',
            icon: FontAwesomeIcons.buildingUser,
            screenIndex: 11),
        MenuItem(
            id: 'permissoes',
            label: 'Permissões',
            icon: FontAwesomeIcons.shieldHalved,
            screenIndex: 59),
        MenuItem(
            id: 'teste_endpoints',
            label: 'Teste de Endpoints',
            icon: FontAwesomeIcons.vials,
            screenIndex: 65),
        MenuItem(
            id: 'query_builder',
            label: 'Query Builder',
            icon: FontAwesomeIcons.database,
            screenIndex: 150),
        MenuItem(
            id: 'sessoes',
            label: 'Sessões',
            icon: FontAwesomeIcons.userClock,
            screenIndex: 186),
      ],
    ),
    MenuGroup(
      id: 'app_academia',
      label: 'App Academia',
      icon: FontAwesomeIcons.dumbbell,
      items: [
        MenuItem(
            id: 'academia',
            label: 'Academias',
            icon: FontAwesomeIcons.building,
            screenIndex: 124),
        MenuItem(
            id: 'alimentos',
            label: 'Alimentos',
            icon: FontAwesomeIcons.appleWhole,
            screenIndex: 9),
        MenuItem(
            id: 'avaliacao_fisica',
            label: 'Avaliação Física',
            icon: FontAwesomeIcons.clipboardList,
            screenIndex: 42),
        MenuItem(
            id: 'dietas',
            label: 'Dietas',
            icon: FontAwesomeIcons.bowlFood,
            screenIndex: 10),
        MenuItem(
            id: 'exercicios',
            label: 'Exercícios',
            icon: FontAwesomeIcons.dumbbell,
            screenIndex: 13),
        MenuItem(
            id: 'grupos_musculares',
            label: 'Grupos Musculares',
            icon: FontAwesomeIcons.peopleGroup,
            screenIndex: 14),
        MenuItem(
            id: 'medicamentos',
            label: 'Medicamentos',
            icon: FontAwesomeIcons.pills,
            screenIndex: 15),
        MenuItem(
            id: 'modalidades',
            label: 'Modalidades',
            icon: FontAwesomeIcons.tableList,
            screenIndex: 17),
        MenuItem(
            id: 'objetivos',
            label: 'Objetivos',
            icon: FontAwesomeIcons.bullseye,
            screenIndex: 18),
        MenuItem(
            id: 'personais',
            label: 'Personais',
            icon: FontAwesomeIcons.userTie,
            screenIndex: 20),
        MenuItem(
            id: 'suplementos',
            label: 'Suplementos',
            icon: FontAwesomeIcons.capsules,
            screenIndex: 24),
        MenuItem(
            id: 'treino',
            label: 'Treino',
            icon: FontAwesomeIcons.personRunning,
            screenIndex: 49),
      ],
    ),
    MenuGroup(
      id: 'bolsa_valores',
      label: 'Bolsa de Valores',
      icon: FontAwesomeIcons.chartLine,
      items: [
        MenuItem(
            id: 'trading_painel',
            label: 'Painel de Trading',
            icon: FontAwesomeIcons.gaugeHigh,
            screenIndex: 72),
        MenuItem(
            id: 'trading_sinais',
            label: 'Sinais de Mercado',
            icon: FontAwesomeIcons.arrowTrendUp,
            screenIndex: 75),
        MenuItem(
            id: 'trading_oportunidades',
            label: 'Oportunidades',
            icon: FontAwesomeIcons.star,
            screenIndex: 76),
        MenuItem(
            id: 'trading_watchlist',
            label: 'Watchlist',
            icon: FontAwesomeIcons.bookmark,
            screenIndex: 77),
        MenuItem(
            id: 'trading_alertas',
            label: 'Alertas de Preço',
            icon: FontAwesomeIcons.bell,
            screenIndex: 78),
        MenuItem(
            id: 'trading_operacoes',
            label: 'Operações Assistidas',
            icon: FontAwesomeIcons.arrowsLeftRight,
            screenIndex: 79),
        MenuItem(
            id: 'trading_backtest',
            label: 'Backtest',
            icon: FontAwesomeIcons.clockRotateLeft,
            screenIndex: 85),
        MenuItem(
            id: 'trading_corretora',
            label: 'Configuração da Corretora',
            icon: FontAwesomeIcons.gear,
            screenIndex: 119),
        MenuItem(
            id: 'trading_carteira',
            label: 'Minha Carteira',
            icon: FontAwesomeIcons.briefcase,
            screenIndex: 120),
      ],
    ),
    MenuGroup(
      id: 'gme',
      label: 'GME',
      icon: FontAwesomeIcons.gears,
      items: [
        MenuItem(
            id: 'dashboard_gme',
            label: 'Dashboard GME',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 156),
        MenuItem(
            id: 'contrato',
            label: 'Contratos',
            icon: FontAwesomeIcons.fileContract,
            screenIndex: 157),
        MenuItem(
            id: 'equipamento',
            label: 'Equipamentos',
            icon: FontAwesomeIcons.toolbox,
            screenIndex: 158),
        MenuItem(
            id: 'ordem_servico',
            label: 'Ordens de Serviço',
            icon: FontAwesomeIcons.clipboardList,
            screenIndex: 159),
        MenuItem(
            id: 'plano_manutencao',
            label: 'Planos de Manutenção',
            icon: FontAwesomeIcons.calendarCheck,
            screenIndex: 160),
        MenuItem(
            id: 'horimetro',
            label: 'Horímetro',
            icon: FontAwesomeIcons.gauge,
            screenIndex: 161),
        MenuItem(
            id: 'historico_manutencao',
            label: 'Histórico Manutenção',
            icon: FontAwesomeIcons.clockRotateLeft,
            screenIndex: 162),
        MenuItem(
            id: 'tecnico_manutencao',
            label: 'Técnicos',
            icon: FontAwesomeIcons.userGear,
            screenIndex: 163),
      ],
    ),
    MenuGroup(
      id: 'service_desk',
      label: 'Service Desk',
      icon: FontAwesomeIcons.headset,
      items: [
        MenuItem(
            id: 'dashboard_service',
            label: 'Dashboard Service',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 164),
        MenuItem(
            id: 'sla',
            label: 'SLA',
            icon: FontAwesomeIcons.stopwatch,
            screenIndex: 165),
        MenuItem(
            id: 'fila_atendimento',
            label: 'Filas de Atendimento',
            icon: FontAwesomeIcons.peopleArrows,
            screenIndex: 166),
        MenuItem(
            id: 'categoria_chamado',
            label: 'Categorias Chamado',
            icon: FontAwesomeIcons.layerGroup,
            screenIndex: 167),
        MenuItem(
            id: 'chamado_avaliacao',
            label: 'Avaliações',
            icon: FontAwesomeIcons.star,
            screenIndex: 168),
      ],
    ),
    MenuGroup(
      id: 'projetos',
      label: 'Projetos',
      icon: FontAwesomeIcons.diagramProject,
      items: [
        MenuItem(
            id: 'dashboard_projetos',
            label: 'Dashboard Projetos',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 169),
        MenuItem(
            id: 'projeto',
            label: 'Projetos',
            icon: FontAwesomeIcons.folderOpen,
            screenIndex: 170),
        MenuItem(
            id: 'projeto_etapa',
            label: 'Etapas',
            icon: FontAwesomeIcons.listOl,
            screenIndex: 171),
        MenuItem(
            id: 'projeto_recurso',
            label: 'Recursos',
            icon: FontAwesomeIcons.users,
            screenIndex: 172),
        MenuItem(
            id: 'projeto_apontamento',
            label: 'Apontamentos',
            icon: FontAwesomeIcons.penToSquare,
            screenIndex: 173),
        MenuItem(
            id: 'projeto_medicao',
            label: 'Medições',
            icon: FontAwesomeIcons.ruler,
            screenIndex: 174),
        MenuItem(
            id: 'cargo_recurso',
            label: 'Cargos/Recursos',
            icon: FontAwesomeIcons.idBadge,
            screenIndex: 175),
      ],
    ),
    MenuGroup(
      id: 'precificacao',
      label: 'Precificação',
      icon: FontAwesomeIcons.calculator,
      items: [
        MenuItem(
            id: 'dashboard_precificacao',
            label: 'Dashboard Precificação',
            icon: FontAwesomeIcons.chartPie,
            screenIndex: 176),
        MenuItem(
            id: 'precificacao',
            label: 'Precificações',
            icon: FontAwesomeIcons.fileInvoiceDollar,
            screenIndex: 177),
        MenuItem(
            id: 'custo_direto',
            label: 'Custos Diretos',
            icon: FontAwesomeIcons.coins,
            screenIndex: 178),
        MenuItem(
            id: 'mao_de_obra',
            label: 'Mão de Obra',
            icon: FontAwesomeIcons.personDigging,
            screenIndex: 179),
        MenuItem(
            id: 'precificacao_servico',
            label: 'Serviços',
            icon: FontAwesomeIcons.screwdriverWrench,
            screenIndex: 180),
        MenuItem(
            id: 'condicao_pagamento',
            label: 'Condições Pagamento',
            icon: FontAwesomeIcons.moneyBill,
            screenIndex: 181),
        MenuItem(
            id: 'proposta_comercial',
            label: 'Propostas Comerciais',
            icon: FontAwesomeIcons.filePen,
            screenIndex: 182),
      ],
    ),
  ];

  static const List<MenuItem> loose = [
    MenuItem(
        id: 'dashboard',
        label: 'Dashboard',
        icon: FontAwesomeIcons.chartBar,
        screenIndex: 45),
    MenuItem(
        id: 'mensalidades',
        label: 'Mensalidades',
        icon: FontAwesomeIcons.moneyBill,
        screenIndex: 16),
    MenuItem(
        id: 'parceiros',
        label: 'Contatos',
        icon: FontAwesomeIcons.addressBook,
        screenIndex: 19),

    MenuItem(
        id: 'pedidos',
        label: 'Pedidos',
        icon: FontAwesomeIcons.cartFlatbed,
        screenIndex: 39),
    MenuItem(
        id: 'fornecedores',
        label: 'Fornecedores',
        icon: FontAwesomeIcons.truck,
        screenIndex: 93),
  ];

  static List<MenuItem> get allItems {
    final all = <MenuItem>[];
    for (final g in groups) {
      all.addAll(g.items);
    }
    all.addAll(loose);
    return all;
  }

  static List<MenuItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final q = query.toLowerCase().trim();
    return allItems.where((m) => m.label.toLowerCase().contains(q)).toList()
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  static MenuGroup? groupOf(String itemId) {
    for (final g in groups) {
      if (g.items.any((i) => i.id == itemId)) return g;
    }
    return null;
  }
}

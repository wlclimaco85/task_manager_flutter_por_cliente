import 'package:task_manager_flutter/services/permission_service.dart';
import 'package:task_manager_flutter/utils/string_utils.dart';
import '../../widgets/dp/dp_dashboard_screen.dart';
import 'nfe_serie_grid_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:task_manager_flutter/models/alert_model.dart';
import 'package:task_manager_flutter/models/auth_utility.dart';
import 'package:task_manager_flutter/services/alert_caller.dart';
import 'package:task_manager_flutter/utils/grid_colors.dart';
import 'package:task_manager_flutter/utils/security_matrix.dart';

import '../../customization/dynamic_grid_dynamic_screen.dart';
import '../../customization/generic_grid/grid_models.dart'
    show CustomAction, FieldConfig, FieldType, FileConfig;
import '../../windows/screens/comunicado_detalhe_screen.dart';
import '../../windows/screens/fechar_chamado_dialog.dart';
import 'sem_acesso_screen.dart';
import '../../auth_screens/login_screen.dart';
import '../../features/trading/trading_dashboard_screen.dart';
import '../../widgets/login_empresa_acesso_aprovacao_screen.dart';
import '../../features/agendamento/agendamento_module.dart';
import '../../features/trading/screens/backtest_screen.dart';
import '../../features/trading/services/backtest_repository.dart';
import '../../services/ged_download_service.dart';
import '../../services/network_caller.dart';
import '../../utils/api_links.dart';
import '../../utils/app_logger.dart';
import '../../utils/tenant_context.dart';
import '../../web/screens/nfce/pdv_screen.dart';
import '../../web/screens/nfce/config_fiscal_screen.dart';
import 'meu_perfil_screen.dart';
import 'ponto_screen.dart';
import '../../widgets/crm/crm_pipeline_screen.dart';
import '../../widgets/fiscal/fiscal_automation_screen.dart';
import 'mensalidade_screen.dart';
import 'conta_pagar_grid_screen.dart';
import 'conta_receber_grid_screen.dart';
import 'conta_bancaria_grid_screen.dart';
import 'parceiro_grid_screen.dart';
import 'login_grid_screen.dart';
import 'nfse_screen.dart';
import 'nfe_grid_screen.dart';
import 'nfce_grid_screen.dart';
import 'nfse_serie_screen.dart';
import 'nfse_servico_screen.dart';
import 'nfse_config_screen.dart';
import 'extrato_importacao_screen.dart' show MobileExtratoImportacaoScreen;
import '../../web/screens/cobranca_automatica_screen.dart';
import '../../widgets/user_banners.dart';
import 'alvara_screen.dart';
import 'role_permissao_mobile_screen.dart';
import '../../widgets/comercial/dashboard_comercial_mercadorias_screen.dart';
import 'dashboard_financeiro_screen.dart';


import 'plano_grid_screen.dart';
import 'tipo_parceiro_grid_screen.dart';
import 'servico_contratado_grid_screen.dart';
import 'modulo_servico_grid_screen.dart';
import 'catalago_produto_grid_screen.dart';
import 'unidade_medida_grid_screen.dart';
import 'orcamento_grid_screen.dart';
import 'pedido_venda_grid_screen.dart';
import 'pedido_compra_grid_screen.dart';
import 'pedido_grid_screen.dart';
import 'aprovacao_compra_screen.dart';
import 'tabela_preco_screen.dart';
import 'devolucao_grid_screen.dart';
import 'fornecedor_grid_screen.dart';
import 'regime_grid_screen.dart';
import 'obrigacao_fiscal_grid_screen.dart';
import 'forma_pagamento_grid_screen.dart';
import 'centro_custo_grid_screen.dart';
import 'categoria_financeira_grid_screen.dart';
import 'lancamento_financeiro_grid_screen.dart';
import 'calendario_guias_grid_screen.dart';
import 'feriado_grid_screen.dart';
import 'setor_grid_screen.dart';
import 'conta_contabil_grid_screen.dart';
import 'lancamento_contabil_grid_screen.dart';
import 'alerta_aluno_grid_screen.dart';
import 'diretorio_grid_screen.dart';
import 'noticias_grid_screen.dart';
import 'alimento_grid_screen.dart';
import 'dieta_grid_screen.dart';
import 'exercicio_grid_screen.dart';
import 'grupo_muscular_grid_screen.dart';
import 'medicamento_grid_screen.dart';
import 'modalidade_grid_screen.dart';
import 'objetivo_grid_screen.dart';
import 'personal_grid_screen.dart';
import 'suplemento_grid_screen.dart';
import 'treino_grid_screen.dart';
import 'avaliacao_fisica_grid_screen.dart';
import 'academia_grid_screen.dart';
import 'aplicativo_screen.dart';
import 'empresa_grid_screen.dart';
import 'role_grid_screen.dart';
import 'configuracoes_admin_screen.dart';
import 'ticket_grid_screen.dart';
import 'cotacao_frete_grid_screen.dart';
import 'dividendo_grid_screen.dart';
import 'order_grid_screen.dart';
import 'classificacao_grid_screen.dart';
import 'departamento_grid_screen.dart';
import 'cargo_grid_screen.dart';
import 'horario_func_grid_screen.dart';

import 'nfe_import_xml_screen.dart';
import 'nfse_import_xml_screen.dart';
import 'nfe_import_screen.dart';
import 'consulta_dfe_screen.dart';
import 'manifestacao_destinatario_screen.dart';
import 'cancelamento_cce_screen.dart';
import 'calendario_tributario_screen.dart';
import 'conciliacao_screen.dart';
import 'rateio_financeiro_screen.dart';
import 'baixa_automatica_screen.dart';
import 'cobranca_screen.dart';
import 'renegociacao_screen.dart';
import 'dre_screen.dart';
import 'cnab_remessa_screen.dart';
import 'kanban_pagamentos_screen.dart';
import 'aprovacao_pagamentos_screen.dart';
import 'boleto_importacao_lote_screen.dart';
import 'integracoes_financeiras_screen.dart';
import 'ponto_ajuste_screen.dart';
import 'ponto_solicitacao_screen.dart';
import 'balancete_screen.dart';
import 'fechamento_periodo_screen.dart';
import 'ai_dashboard_screen.dart';
import 'ai_assistente_screen.dart';
import 'kanban_chamados_screen.dart';
import 'kanban_chat_screen.dart';
import 'instagram_monitor_screen.dart';
import 'reserva_estoque_screen.dart';
import 'deposito_screen.dart';
import 'certificado_digital_screen.dart';
import 'configuracoes_sistema_screen.dart';
import 'editor_telas_screen.dart';
import 'cadastro_empresa_wizard.dart';
import 'importacao_fiscal_automacao_screen.dart';
import 'solicitacoes_acesso_screen.dart';
import 'query_builder_window_screen.dart';
import 'sessoes_screen.dart';
import 'anamnese_screen.dart';
import 'trading_screens.dart';
import 'regra_fiscal_screen.dart';
import 'dashboard_mensalidade_screen.dart';
import 'system_test_screen.dart';
import 'relatorio_ponto_screen.dart';
import '../../widgets/dashboard_executivo_screen.dart';

class BottomNavBarScreen extends StatefulWidget {
  const BottomNavBarScreen({super.key});

  @override
  State<BottomNavBarScreen> createState() => _BottomNavBarScreenState();
}

class _BottomNavBarScreenState extends State<BottomNavBarScreen> {
  
  static const Map<String, ({String menuId, AppScreen? appScreen})> _menuActionConfig = {
    'PDV': (menuId: 'pdv_nfce', appScreen: AppScreen.pdvNfce),
    'Produtos': (menuId: 'produtos', appScreen: AppScreen.produto),
    'Parceiros': (menuId: 'parceiros', appScreen: AppScreen.parceiros),
    'Fornecedores': (menuId: 'fornecedores', appScreen: AppScreen.fornecedores),
    'Planos': (menuId: 'planos', appScreen: AppScreen.planos),
    'Tipos de Parceiro': (menuId: 'tipo_parceiro', appScreen: AppScreen.tipoParceiro),
    'Serviços Contratados': (menuId: 'servicos_contratados', appScreen: AppScreen.servicoContratado),
    'Módulos de Serviço': (menuId: 'modulos_servicos', appScreen: AppScreen.moduloServico),
    'Catálogo de Produtos': (menuId: 'catalogo_produto', appScreen: AppScreen.catalogoProduto),
    'Unidades de Medida': (menuId: 'unidade_medida', appScreen: AppScreen.unidadeMedida),
    'Orçamentos': (menuId: 'orcamentos', appScreen: null),
    'Pedidos de Venda': (menuId: 'pedidos_venda', appScreen: null),
    'Pedidos de Compra': (menuId: 'pedidos_compra', appScreen: null),
    'Pedidos': (menuId: 'pedidos', appScreen: AppScreen.pedidos),
    'Aprovação de Compras': (menuId: 'aprovacao_compra', appScreen: AppScreen.aprovacaoCompra),
    'Tabela de Preços': (menuId: 'tabela_preco', appScreen: AppScreen.tabelaPreco),
    'Devoluções': (menuId: 'devolucoes', appScreen: AppScreen.devolucoes),
    'Reserva de Estoque': (menuId: 'reserva_estoque', appScreen: AppScreen.reservaEstoque),
    'Multi-depósito': (menuId: 'multi_deposito', appScreen: AppScreen.multiDeposito),
    'Dashboard Comercial': (menuId: 'dashboard_comercial', appScreen: AppScreen.dashComercialArea),
    'Contas Pagar': (menuId: 'contas_pagar', appScreen: AppScreen.contasPagar),
    'Contas Receber': (menuId: 'contas_receber', appScreen: AppScreen.contasReceber),
    'Contas Bancarias': (menuId: 'conta_bancaria', appScreen: AppScreen.contasBancarias),
    'Formas de Pagamento': (menuId: 'formas_pagamento', appScreen: AppScreen.formasPagamento),
    'Centros de Custo': (menuId: 'centros_custo', appScreen: null),
    'Categorias Financeiras': (menuId: 'categorias_financeiras', appScreen: null),
    'Lançamentos Financeiros': (menuId: 'lancamentos_financeiros', appScreen: AppScreen.lancamentosFinanceiros),
    'Importar Extratos': (menuId: 'importar_extrato', appScreen: AppScreen.importarExtrato),
    'Conciliação Bancária': (menuId: 'conciliacao_bancaria', appScreen: AppScreen.conciliacaoBancaria),
    'Rateio Financeiro': (menuId: 'rateio_financeiro', appScreen: null),
    'Baixa Automática': (menuId: 'baixa_automatica', appScreen: null),
    'Renegociação': (menuId: 'renegociacao', appScreen: null),
    'Cobrança': (menuId: 'cobranca', appScreen: AppScreen.cobranca),
    'Régua de Cobrança': (menuId: 'contas_receber', appScreen: AppScreen.contasReceber),
    'DRE Gerencial': (menuId: 'dre_gerencial', appScreen: AppScreen.dreGerencial),
    'Envio EDI (Remessa)': (menuId: 'cnab_remessa', appScreen: AppScreen.cnabRemessa),
    'Kanban de Pagamentos': (menuId: 'kanban_pagamentos', appScreen: null),
    'Aprovação de Pagamentos': (menuId: 'aprovacao_pagamentos_web', appScreen: AppScreen.aprovacaoPagamentos),
    'Cobrança Automática': (menuId: 'cobranca_automatica', appScreen: AppScreen.cobrancaAutomatica),
    'Dashboard Mensalidades': (menuId: 'dashboard_mensalidades', appScreen: AppScreen.dashMensalidadeArea),
    'Mensalidades': (menuId: 'mensalidades', appScreen: AppScreen.mensalidades),
    'Calendário de Guias': (menuId: 'calendario_guias', appScreen: null),
    'Importar Boletos (Lote)': (menuId: 'importar_boletos_lote', appScreen: AppScreen.boletoImportacaoLote),
    'Integrações Financeiras': (menuId: 'integracoes_financeiras', appScreen: AppScreen.integracoesFinanceiras),
    'Dashboard': (menuId: 'dashboard', appScreen: AppScreen.dashboard),
    'Dashboard Financeiro': (menuId: 'dashboard_financeiro', appScreen: AppScreen.dashFinanceiroArea),
    'NF-e Saída': (menuId: 'nfe_saida', appScreen: AppScreen.nfeSaida),
    'NF-e Entrada': (menuId: 'nfe_entrada', appScreen: AppScreen.nfeEntrada),
    'NFC-e (Cupons)': (menuId: 'nfce_grid', appScreen: AppScreen.nfceGrid),
    'NF-e Série': (menuId: 'nfe_serie', appScreen: AppScreen.nfeSerie),
    'NF-e Finalidade': (menuId: 'nfe_finalidade', appScreen: null),
    'NF-e Tipo Operação': (menuId: 'nfe_tipo_operacao', appScreen: null),
    'Importar XML NF-e': (menuId: 'nfe_import_xml', appScreen: null),
    'Importar NF-e CSV': (menuId: 'nfe_import_csv', appScreen: null),
    'Consulta DF-e': (menuId: 'consulta_dfe', appScreen: null),
    'Manifestação Destinatário': (menuId: 'manifestacao_destinatario', appScreen: null),
    'Cancelamento e CC-e': (menuId: 'cancelamento_cce', appScreen: null),
    'Agendar NFe Recorrente': (menuId: 'agendamento_nfe', appScreen: null),
    'Regime Tributário': (menuId: 'regime_tributario', appScreen: AppScreen.regimeTributario),
    'Regras Fiscais': (menuId: 'regra_fiscal', appScreen: AppScreen.regraFiscal),
    'Obrigações Fiscais': (menuId: 'obrigacoes_fiscais', appScreen: AppScreen.obrigacoesFiscais),
    'Calendário Tributário': (menuId: 'calendario_guias', appScreen: null),
    'Dashboard Fiscal': (menuId: 'dashboard_fiscal', appScreen: AppScreen.dashFiscalArea),
    'Notas de Serviço (NFS-e)': (menuId: 'nfse', appScreen: AppScreen.nfseLista),
    'Séries NFS-e': (menuId: 'nfse_serie', appScreen: AppScreen.nfseSerie),
    'Serviços NFS-e': (menuId: 'nfse_servico', appScreen: AppScreen.nfseServico),
    'Importar XML NFS-e': (menuId: 'nfse_import_xml', appScreen: null),
    'Config ISS': (menuId: 'config_fiscal', appScreen: AppScreen.configFiscal),
    'Bater Ponto': (menuId: 'ponto', appScreen: AppScreen.ponto),
    'Funcionários': (menuId: 'funcionario', appScreen: AppScreen.funcionarios),
    'Solicitar Ajuste': (menuId: 'solicitar_ajuste', appScreen: AppScreen.solicitacaoAjustePonto),
    'Ajuste de Ponto': (menuId: 'ajuste_ponto', appScreen: AppScreen.ajustePonto),
    'Feriados': (menuId: 'feriados', appScreen: AppScreen.feriados),
    'Setores': (menuId: 'setores', appScreen: AppScreen.setores),
    'Horários Funcionário': (menuId: 'horario_func', appScreen: null),
    'Dashboard DP': (menuId: 'dashboard_dp', appScreen: AppScreen.dashDpArea),
    'Relatórios DP/RH': (menuId: 'relatorio_dp_rh', appScreen: AppScreen.relatorioDpRh),
    'Plano de Contas': (menuId: 'conta_contabil', appScreen: null),
    'Lançamentos Contábeis': (menuId: 'lancamento_contabil', appScreen: AppScreen.lancamentoContabil),
    'Balancete': (menuId: 'balancete', appScreen: AppScreen.balancete),
    'Fechamento de Período': (menuId: 'fechamento_periodo', appScreen: AppScreen.fechamentoPeriodo),
    'Dashboard IA': (menuId: 'ai_dashboard', appScreen: AppScreen.aiDashboard),
    'Assistente IA': (menuId: 'ai_assistente', appScreen: AppScreen.aiAssistente),
    'Alertas': (menuId: 'alertas', appScreen: null),
    'Diretórios': (menuId: 'diretorios', appScreen: AppScreen.diretorios),
    'Notícias': (menuId: 'noticias', appScreen: AppScreen.noticias),
    'Kanban Chamados': (menuId: 'kanban', appScreen: AppScreen.kanbanChamados),
    'Kanban Chat': (menuId: 'kanban_chat', appScreen: AppScreen.chatKanban),
    'Instagram Monitor': (menuId: 'instagram_monitor', appScreen: null),
    'Academias': (menuId: 'academia', appScreen: null),
    'Alimentos': (menuId: 'alimentos', appScreen: AppScreen.alimentos),
    'Dietas': (menuId: 'dietas', appScreen: AppScreen.dietas),
    'Exercícios': (menuId: 'exercicios', appScreen: AppScreen.exercicios),
    'Grupos Musculares': (menuId: 'grupos_musculares', appScreen: AppScreen.gruposMusculares),
    'Medicamentos': (menuId: 'medicamentos', appScreen: AppScreen.medicamentos),
    'Modalidades': (menuId: 'modalidades', appScreen: AppScreen.modalidades),
    'Objetivos': (menuId: 'objetivos', appScreen: AppScreen.objetivos),
    'Personais': (menuId: 'personais', appScreen: AppScreen.personais),
    'Suplementos': (menuId: 'suplementos', appScreen: AppScreen.suplementos),
    'Treinos': (menuId: 'treino', appScreen: null),
    'Avaliação Física': (menuId: 'avaliacao_fisica', appScreen: AppScreen.exames),
    'Anamnese': (menuId: 'anamnese', appScreen: null),
    'Trading': (menuId: 'trading_painel', appScreen: AppScreen.trading),
    'Backtesting': (menuId: 'trading_backtest', appScreen: null),
    'Sinais de Mercado': (menuId: 'trading_sinais', appScreen: null),
    'Oportunidades': (menuId: 'trading_oportunidades', appScreen: null),
    'Watchlist': (menuId: 'trading_watchlist', appScreen: null),
    'Alertas de Preço': (menuId: 'trading_alertas', appScreen: null),
    'Operações Assistidas': (menuId: 'trading_operacoes', appScreen: null),
    'Configuração da Corretora': (menuId: 'trading_corretora', appScreen: null),
    'Minha Carteira': (menuId: 'trading_carteira', appScreen: null),
    'Dashboard GME': (menuId: 'dashboard_gme', appScreen: null),
    'Contratos GME': (menuId: 'contrato', appScreen: null),
    'Equipamentos': (menuId: 'equipamento', appScreen: null),
    'Ordens de Serviço': (menuId: 'ordem_servico', appScreen: null),
    'Planos Manutenção': (menuId: 'plano_manutencao', appScreen: null),
    'Horímetro': (menuId: 'horimetro', appScreen: null),
    'Histórico Manutenção': (menuId: 'historico_manutencao', appScreen: null),
    'Técnicos': (menuId: 'tecnico_manutencao', appScreen: null),
    'Dashboard Service': (menuId: 'dashboard_service', appScreen: null),
    'SLA': (menuId: 'sla', appScreen: null),
    'Filas Atendimento': (menuId: 'fila_atendimento', appScreen: null),
    'Categorias Chamado': (menuId: 'categoria_chamado', appScreen: null),
    'Avaliações': (menuId: 'chamado_avaliacao', appScreen: null),
    'Dashboard Projetos': (menuId: 'dashboard_projetos', appScreen: null),
    'Projetos': (menuId: 'projeto', appScreen: null),
    'Etapas Projeto': (menuId: 'projeto_etapa', appScreen: null),
    'Recursos Projeto': (menuId: 'projeto_recurso', appScreen: null),
    'Apontamentos': (menuId: 'projeto_apontamento', appScreen: null),
    'Medições': (menuId: 'projeto_medicao', appScreen: null),
    'Cargos/Recursos': (menuId: 'cargo_recurso', appScreen: null),
    'Dashboard Precificação': (menuId: 'dashboard_precificacao', appScreen: null),
    'Precificações': (menuId: 'precificacao', appScreen: null),
    'Custos Diretos': (menuId: 'custo_direto', appScreen: null),
    'Mão de Obra': (menuId: 'mao_de_obra', appScreen: null),
    'Serviços Precificação': (menuId: 'precificacao_servico', appScreen: null),
    'Condições Pagamento': (menuId: 'condicao_pagamento', appScreen: null),
    'Propostas Comerciais': (menuId: 'proposta_comercial', appScreen: null),
    'Aplicativo': (menuId: 'aplicativo', appScreen: AppScreen.aplicativo),
    'Empresas': (menuId: 'empresas', appScreen: AppScreen.empresas),
    'Usuários': (menuId: 'logins', appScreen: AppScreen.logins),
    'Roles': (menuId: 'roles', appScreen: AppScreen.roles),
    'Alvarás': (menuId: 'alvaras', appScreen: AppScreen.alvaras),
    'Configurações Admin': (menuId: 'config_admin', appScreen: AppScreen.configuracoesAdmin),
    'Configurações Sistema': (menuId: 'config_sistema', appScreen: AppScreen.configSistema),
    'Editor de Telas': (menuId: 'editor_telas', appScreen: null),
    'Cadastro de Empresa': (menuId: 'cadastro_empresa', appScreen: null),
    'Importação Fiscal Automação': (menuId: 'importacao_fiscal_automacao', appScreen: null),
    'Certificado Digital': (menuId: 'certificado_digital', appScreen: null),
    'Solicitações de Acesso': (menuId: 'solicitacoes_acesso', appScreen: null),
    'Permissões Multi-Empresa': (menuId: 'permissoes_multi_empresa', appScreen: null),
    'Query Builder': (menuId: 'query_builder', appScreen: null),
    'Sessões': (menuId: 'sessoes', appScreen: null),
    'Meu Perfil': (menuId: 'perfil', appScreen: AppScreen.perfil),
    'Controle de Acesso': (menuId: 'permissoes', appScreen: AppScreen.rolesPermissoes),
    'Config Fiscal': (menuId: 'config_fiscal', appScreen: AppScreen.configFiscal),
    'Teste de Endpoints': (menuId: 'teste_endpoints', appScreen: AppScreen.sistemaTest),
    'Sair': (menuId: 'sair', appScreen: null),
  };

  /// Mapeamento de menuItemId para o módulo contratado correspondente
  static const Map<String, String> _menuItemToModulo = {
    // Comercial
    'pdv_nfce': 'Comercial',
    'produtos': 'Comercial',
    'parceiros': 'Comercial',
    'fornecedores': 'Comercial',
    'planos': 'Comercial',
    'tipo_parceiro': 'Comercial',
    'servicos_contratados': 'Comercial',
    'modulos_servicos': 'Comercial',
    'catalogo_produto': 'Comercial',
    'unidade_medida': 'Comercial',
    'orcamentos': 'Comercial',
    'pedidos_venda': 'Comercial',
    'pedidos_compra': 'Comercial',
    'pedidos': 'Comercial',
    'aprovacao_compra': 'Comercial',
    'tabela_preco': 'Comercial',
    'devolucoes': 'Comercial',
    'reserva_estoque': 'Comercial',
    'multi_deposito': 'Comercial',
    'dashboard_comercial': 'Comercial',

    // Financeiro
    'contas_pagar': 'Financeiro',
    'contas_receber': 'Financeiro',
    'conta_bancaria': 'Financeiro',
    'formas_pagamento': 'Financeiro',
    'centros_custo': 'Financeiro',
    'categorias_financeiras': 'Financeiro',
    'lancamentos_financeiros': 'Financeiro',
    'importar_extrato': 'Financeiro',
    'conciliacao_bancaria': 'Financeiro',
    'rateio_financeiro': 'Financeiro',
    'baixa_automatica': 'Financeiro',
    'renegociacao': 'Financeiro',
    'cobranca': 'Financeiro',
    'cobranca_automatica': 'Financeiro',
    'dre_gerencial': 'Financeiro',
    'cnab_remessa': 'Financeiro',
    'kanban_pagamentos': 'Financeiro',
    'aprovacao_pagamento': 'Financeiro',
    'calendario_guias': 'Financeiro',
    'importar_boletos_lote': 'Financeiro',
    'integracoes_financeiras': 'Financeiro',
    'dashboard': 'Financeiro',
    'dashboard_financeiro': 'Financeiro',

    // Fiscal / Notas Fiscais
    'nfe_saida': 'Notas Fiscais',
    'nfe_entrada': 'Notas Fiscais',
    'nfce_grid': 'Notas Fiscais',
    'nfe_serie': 'Notas Fiscais',
    'nfe_finalidade': 'Notas Fiscais',
    'nfe_tipo_operacao': 'Notas Fiscais',
    'nfe_import_xml': 'Notas Fiscais',
    'nfe_import_csv': 'Notas Fiscais',
    'consulta_dfe': 'Notas Fiscais',
    'manifestacao_destinatario': 'Notas Fiscais',
    'cancelamento_cce': 'Notas Fiscais',
    'agendamento_nfe': 'Notas Fiscais',
    'regime_tributario': 'Notas Fiscais',
    'obrigacoes_fiscais': 'Notas Fiscais',
    'calendario_tributario': 'Notas Fiscais',
    'dashboard_fiscal': 'Notas Fiscais',

    // NFS-e
    'nfse': 'NFS-e',
    'nfse_serie': 'NFS-e',
    'nfse_servico': 'NFS-e',
    'nfse_import_xml': 'NFS-e',
    'config_fiscal': 'NFS-e',

    // Depto Pessoal
    'ponto': 'Departamento Pessoal',
    'funcionario': 'Departamento Pessoal',
    'solicitar_ajuste': 'Departamento Pessoal',
    'ajuste_ponto': 'Departamento Pessoal',
    'feriados': 'Departamento Pessoal',
    'setores': 'Departamento Pessoal',
    'horario_func': 'Departamento Pessoal',
    'dashboard_dp': 'Departamento Pessoal',

    // Contábil
    'conta_contabil': 'Contábil',
    'lancamento_contabil': 'Contábil',
    'balancete': 'Contábil',
    'fechamento_periodo': 'Contábil',
    'ai_dashboard': 'Contábil',
    'ai_assistente': 'Contábil',

    // Suporte / Comunicação
    'alertas': 'Comunicados',
    'diretorios': 'GED',
    'noticias': 'Comunicados',
    'kanban': 'Chamados',
    'kanban_chat': 'Chat',

    // Academia & Saúde
    'academia': 'Academia',
    'alimentos': 'Academia',
    'dietas': 'Academia',
    'exercicios': 'Academia',
    'grupos_musculares': 'Academia',
    'medicamentos': 'Academia',
    'modalidades': 'Academia',
    'objetivos': 'Academia',
    'personais': 'Academia',
    'suplementos': 'Academia',
    'treino': 'Academia',
    'avaliacao_fisica': 'Academia',
    'anamnese': 'Academia',

    // Bolsa de Valores
    'trading_painel': 'Bolsa de Valores',
    'trading_backtest': 'Bolsa de Valores',
    'trading_sinais': 'Bolsa de Valores',
    'trading_oportunidades': 'Bolsa de Valores',
    'trading_watchlist': 'Bolsa de Valores',
    'trading_alertas': 'Bolsa de Valores',
    'trading_operacoes': 'Bolsa de Valores',
    'trading_corretora': 'Bolsa de Valores',
    'trading_carteira': 'Bolsa de Valores',

    // GME
    'dashboard_gme': 'GME',
    'contrato': 'GME',
    'equipamento': 'GME',
    'ordem_servico': 'GME',
    'plano_manutencao': 'GME',
    'horimetro': 'GME',
    'historico_manutencao': 'GME',
    'tecnico_manutencao': 'GME',

    // Service Desk
    'dashboard_service': 'Service Desk',
    'sla': 'Service Desk',
    'fila_atendimento': 'Service Desk',
    'categoria_chamado': 'Service Desk',
    'chamado_avaliacao': 'Service Desk',

    // Projetos
    'dashboard_projetos': 'Projetos',
    'projeto': 'Projetos',
    'projeto_etapa': 'Projetos',
    'projeto_recurso': 'Projetos',
    'projeto_apontamento': 'Projetos',
    'projeto_medicao': 'Projetos',
    'cargo_recurso': 'Projetos',

    // Precificação
    'dashboard_precificacao': 'Precificação',
    'precificacao': 'Precificação',
    'custo_direto': 'Precificação',
    'mao_de_obra': 'Precificação',
    'precificacao_servico': 'Precificação',
    'condicao_pagamento': 'Precificação',
    'proposta_comercial': 'Precificação',
  };

  /// Verifica se um determinado módulo está contratado para o tenant atual
  static bool _isModuloAllowed(String moduloNome) {
    final contratados = ModuloAccess.modulosContratados;
    // Módulos legados opcionais: só são liberados se contratados especificamente
    if (moduloNome == 'GME') return contratados.contains('GME');
    if (moduloNome == 'Service Desk') {
      return contratados.contains('Service Desk') ||
          contratados.contains('Service');
    }
    if (moduloNome == 'Projetos') return contratados.contains('Projetos');
    if (moduloNome == 'Precificação') {
      return contratados.contains('Precificação') ||
          contratados.contains('Precificacao');
    }

    if (!ModuloAccess.hasModulosConfigurados) return true;
    switch (moduloNome) {
      case 'Comercial':
        return contratados.contains('Comercial');
      case 'Financeiro':
        return contratados.contains('Financeiro') ||
            contratados.contains('Financeiro Limitado') ||
            contratados.contains('Financeiro avançado') ||
            contratados.contains('Financeiro avancado');
      case 'Notas Fiscais':
      case 'Fiscal':
        return contratados.contains('Notas Fiscais') ||
            contratados.contains('Fiscal') ||
            contratados.contains('Fiscal / NFC-e') ||
            contratados.contains('Fiscal e NF-e') ||
            contratados.contains('NFC-e');
      case 'NFS-e':
        return contratados.contains('NFS-e') || contratados.contains('NFSe');
      case 'Departamento Pessoal':
        return contratados.contains('Departamento Pessoal') ||
            contratados.contains('RH') ||
            contratados.contains('Recursos Humanos');
      case 'Contábil':
        return contratados.contains('Contábil') ||
            contratados.contains('Contabil');
      case 'Chamados':
        return contratados.contains('Chamados');
      case 'Chat':
        return contratados.contains('Chat');
      case 'Comunicados':
        return contratados.contains('Comunicados');
      case 'GED':
        return contratados.contains('GED');
      case 'Academia':
        return contratados.contains('Academia') ||
            contratados.contains('App Academia');
      case 'Bolsa de Valores':
        return contratados.contains('Bolsa de Valores') ||
            contratados.contains('Trading');
      default:
        return contratados.contains(moduloNome);
    }
  }

  /// Verifica se o usuário tem permissão para visualizar uma tela no mobile,
  /// seguindo rigorosamente a mesma matriz de segurança e permissões de role do Web.
  bool _canSeeOption(String optionTitle, SecurityMatrix sec) {
    if (optionTitle == 'Sair' || optionTitle == 'Meu Perfil') return true;

    final config = _menuActionConfig[optionTitle];
    final menuItemId = config?.menuId ?? optionTitle.toLowerCase();
    final appScreen = config?.appScreen;

    // Itens exclusivos do dono do sistema (wlclimaco@gmail.com)
    const ownerOnly = {'match', 'timeline', 'instagram_monitor'};
    if (ownerOnly.contains(menuItemId)) {
      final email = AuthUtility.userInfo?.login?.email?.toLowerCase() ?? '';
      return email == 'wlclimaco@gmail.com';
    }

    // Itens exclusivos de MASTER
    const masterOnly = {
      'sessoes',
      'config_admin',
      'config_sistema',
      'editor_telas',
      'cadastro_empresa',
      'query_builder',
      'aplicativo',
    };
    if (masterOnly.contains(menuItemId)) {
      return sec.isMaster;
    }

    // MASTER / SYSTEM tem acesso total (respeitando módulo se configurado)
    if (sec.isMaster) {
      return ModuloAccess.isMenuItemAllowed(menuItemId);
    }

    // Bater Ponto: acao pessoal, so aparece com permissao EXPLICITA de ver 'ponto'
    // na role (sem cair na matriz padrao do perfil, que liberava para todos).
    if (menuItemId == 'ponto') {
      return ModuloAccess.isMenuItemAllowed(menuItemId) &&
          PermissionService().canViewScreen('ponto');
    }

    // 1. CHECAGEM DE MÓDULO CONTRATADO:
    if (!ModuloAccess.isMenuItemAllowed(menuItemId)) {
      return false;
    }
    if (appScreen != null && ModuloAccess.hasModulosConfigurados && !ModuloAccess.isScreenAllowed(appScreen)) {
      return false;
    }

    // 2. PERMISSÕES DINÂMICAS DA ROLE VINDAS DO BACKEND (RBAC via PermissionService):
    // Quando o usuário possui permissões carregadas do backend, a permissão
    // da Role é a fonte de verdade absoluta (mesma regra do Web).
    if (PermissionService().hasPermissoes) {
      if (menuItemId == 'agendamento_nfe') {
        return PermissionService().canViewScreen('agendamento_nfe') ||
            PermissionService().canViewScreen('pdv_nfce') ||
            PermissionService().canViewScreen('nfe_saida') ||
            PermissionService().canViewScreen('dashboard_fiscal');
      }
      return PermissionService().canViewScreen(menuItemId);
    }

    // 3. MÓDULOS LEGADOS SEM RBAC SEPARADO (GME, Service Desk, Projetos, Precificação):
    const modulosLegados = {'GME', 'Service Desk', 'Projetos', 'Precificação'};
    final moduloLegado = _menuItemToModulo[menuItemId];
    if (moduloLegado != null && modulosLegados.contains(moduloLegado)) {
      return _isModuloAllowed(moduloLegado);
    }

    // 4. PERMISSÕES VIA SECURITYMATRIX (fallback para perfis legados sem permissões do backend):
    // REGRA DE OURO: 'ponto' é registro de jornada e NUNCA deve ser liberado por fallback genérico de escritório.
    // Exige permissão explícita ou role específica de ponto.
    if (menuItemId == 'ponto' || appScreen == AppScreen.ponto) {
      if (PermissionService().hasPermissoes) {
        return PermissionService().canViewScreen('ponto');
      }
      return sec.hasRoleKey('ROLE_PONTO') || sec.profile == UserProfile.ponto;
    }

    if (appScreen != null) {
      return sec.canView(appScreen);
    }

    final camelCaseId = StringUtils.snakeToCamelCase(menuItemId);
    final allKnown = {camelCaseId};
    final allowed = sec.allowedTelaIds(allKnown);
    return allowed != null && allowed.contains(camelCaseId);
  }

  /// Resolve permissão para uma ação específica na tela (CRUD)
  bool _hasActionPermission(SecurityMatrix sec, String menuItemId, String action, [AppScreen? appScreen]) {
    if (sec.isMaster) return true;

    if (appScreen != null) {
      return _hasPermissionFor(sec, appScreen, action);
    }

    final perm = PermissionService().getPermission(menuItemId);
    if (perm != null) {
      final act = action.toLowerCase();
      if (act == 'insert' || act == 'create') return perm.podeInserir;
      if (act == 'update' || act == 'edit') return perm.podeEditar;
      if (act == 'delete' || act == 'remove') return perm.podeDeletar;
      if (act == 'baixar' || act == 'baixa') return perm.podeBaixar;
      return perm.podeVer;
    }

    return sec.canView(appScreen ?? AppScreen.dashboard);
  }

  /// Retorna callback de checagem de permissão para passar aos widgets
  bool Function(String action) _resolvePermissionForOption(String title, SecurityMatrix sec) {
    final config = _menuActionConfig[title];
    final menuId = config?.menuId ?? title.toLowerCase();
    final appScreen = config?.appScreen;
    return (String action) => _hasActionPermission(sec, menuId, action, appScreen);
  }


  int selectedIndex = 0;

  List<Alert> _notifications = [];
  int _unreadCount = 0;
  Timer? _alertTimer;

  @override
  void initState() {
    super.initState();
    if (!ModuloAccess.isLoaded) {
      ModuloAccess.load().then((_) {
        if (mounted) setState(() {});
      }).catchError((_) {});
    }
    _fetchAlerts();
    _alertTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) _fetchAlerts();
    });
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchAlerts() async {
    try {
      final data = await AlertCaller().fetchNotificacoes(context);
      if (mounted) {
        setState(() {
          _notifications = data;
          _unreadCount = data.length;
        });
      }
    } catch (_) {}
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setLocal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Notificacoes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: GridColors.textSecondary,
                      ),
                    ),
                  ),
                  if (_notifications.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _notifications.clear();
                          _unreadCount = 0;
                        });
                        setLocal(() {});
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_sweep, size: 18),
                      label: const Text('Limpar tudo'),
                      style: TextButton.styleFrom(
                          foregroundColor: GridColors.error),
                    ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _notifications.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Sem notificacoes',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 16),
                      itemBuilder: (_, i) {
                        final n = _notifications[i];
                        final dt = DateTime.tryParse(n.data ?? '');
                        final fmt = dt != null
                            ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
                            : '';
                        return ListTile(
                          leading: const Icon(Icons.notifications_outlined,
                              color: GridColors.primary),
                          title: Text(n.texto,
                              style: const TextStyle(fontSize: 13)),
                          subtitle: fmt.isNotEmpty ? Text(fmt) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close,
                                size: 18, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _notifications.removeWhere((x) => x.id == n.id);
                                _unreadCount = _notifications.length;
                              });
                              setLocal(() {});
                            },
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScreens(SecurityMatrix sec) {
    final items = <Widget>[];

    // 1. Início = Dashboard Executivo Gerencial (Conta Própria)
    items.add(
      DashboardExecutivoScreen(
        key: const ValueKey('inicio_dashboard'),
        onNavigateToScreen: (idx) => _navigateToScreenIndex(idx, sec),
      ),
    );

    // 2. Financeiro = Contas a Receber
    items.add(
      sec.canView(AppScreen.contasReceber)
          ? ContaReceberGridScreen(
              key: const ValueKey('inicio_financeiro'),
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasReceber, action),
            )
          : _buildGatedPlaceholder('Financeiro indisponível'),
    );

    // 3. Vendas = Pedidos de Venda
    items.add(
      const MobilePedidoVendaGridScreen(
        key: ValueKey('inicio_vendas'),
      ),
    );

    // 4. Contatos = Clientes e Fornecedores
    items.add(
      sec.canView(AppScreen.parceiros)
          ? ParceiroGridScreen(
              key: const ValueKey('inicio_contatos'),
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.parceiros, action),
            )
          : _buildGatedPlaceholder('Contatos indisponível'),
    );

    // 5. Mais (sempre presente — abre bottom sheet agrupado)
    items.add(Container(key: const ValueKey('mais')));

    return items;
  }

  void _navigateToScreenIndex(int screenIndex, SecurityMatrix sec) {
    switch (screenIndex) {
      case 26: // Contas a Receber
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaReceberGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasReceber, action),
            ),
          ),
        );
        break;
      case 25: // Contas a Pagar
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaPagarGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasPagar, action),
            ),
          ),
        );
        break;
      case 19: // Contatos
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.parceiros, action),
            ),
          ),
        );
        break;
      case 39:
      case 95: // Pedidos de Venda
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MobilePedidoVendaGridScreen(),
          ),
        );
        break;
      case 53: // Produtos
        _pushDynamicGrid(
          telaNome: 'produto',
          sec: sec,
          screen: AppScreen.produto,
        );
        break;
      default:
        break;
    }
  }

  /// Placeholder para slots sem permissão (evita IndexedStack quebrar e tela totalmente em branco).
  Widget _buildGatedPlaceholder(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 48,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GridColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Você não possui permissão para acessar esta tela.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _gedDynamicGrid(SecurityMatrix sec) {
    final empId = TenantContext.empresaId;
    final parcId = TenantContext.parceiroId;
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_dynamic_inline_ged_arquivo'),
      telaNome: 'arquivo',
      // GED mobile so permite visualizar e excluir automaticamente; editar
      // arquivo nao faz sentido (substituicao e feita via novo upload) e as
      // acoes de servidor da tela nao pertencem a este modulo (ver acoes
      // customizadas abaixo, ex.: Baixar).
      hasPermission: (action) {
        final lower = action.toLowerCase();
        if (lower == 'update' || lower == 'edit') return false;
        return _hasPermissionFor(sec, AppScreen.ged, action);
      },
      suppressServerActions: true,
      storageKey: 'mobile_dynamic_ged_arquivo',
      fetchEndpointOverride: ApiLinks.allArquivos,
      createEndpointOverride: ApiLinks.uploadArquivo,
      updateEndpointOverride: ApiLinks.updateArquivo(':id'),
      deleteEndpointOverride: ApiLinks.deleteArquivo(':id'),
      extraParams: {
        if (empId != null) 'empresaId': empId.toString(),
        if (parcId != null) 'parceiroId': parcId.toString(),
      },
      fieldOverrides: _gedFieldOverrides(),
      customActions: () => [
        CustomAction(
          icon: Icons.download_outlined,
          label: 'Baixar arquivo',
          onPressed: (ctx, item) => _baixarArquivo(ctx, item),
          isVisible: (_) => true,
        ),
        CustomAction(
          icon: Icons.drive_file_rename_outline,
          label: 'Renomear',
          onPressed: (ctx, item) => _renomearArquivo(ctx, item),
          isVisible: (_) => true,
        ),
      ],
    );
  }

  /// Baixa o arquivo do GED (mobile) — mesma acao ja existente no Web.
  ///
  /// Bug de producao: quando `item['id']` nao dava pra converter pra int,
  /// a funcao retornava na hora (`if (id == null) return;`) SEM nenhum
  /// feedback -- nem SnackBar, nem log -- exatamente o "clica e nao
  /// acontece nada" reportado. E mesmo os catches existentes so mostravam
  /// SnackBar, sem chamar AppLogger -- entao um erro real de rede/download
  /// tambem nunca aparecia no Console de Logs local nem no monitoramento
  /// de producao (AppLogger.error/warn e' o que alimenta o
  /// SistemaErrorReporter, ver app_logger.dart). Agora todo caminho de
  /// falha loga E mostra feedback.
  Future<void> _baixarArquivo(
      BuildContext ctx, Map<String, dynamic> item) async {
    final id = int.tryParse('${item['id']}');
    if (id == null) {
      AppLogger.i.warn(
        'Download de GED cancelado: item sem id valido (${item['id']}). item=$item',
      );
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível identificar o arquivo para baixar.'),
          ),
        );
      }
      return;
    }
    final nome = (item['fileName'] ?? item['nome'] ?? 'arquivo_$id').toString();
    try {
      final caminho = await GedDownloadService().download(id, nome);
      AppLogger.i.info('GED: arquivo $id ($nome) baixado e compartilhado -> $caminho');
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Arquivo baixado com sucesso.')),
      );
    } on GedDownloadException catch (e, st) {
      AppLogger.i.error('GED: falha ao baixar arquivo $id ($nome): $e', st);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Erro ao baixar arquivo: ${e.statusCode}')),
      );
    } catch (e, st) {
      AppLogger.i.error('GED: falha ao baixar arquivo $id ($nome): $e', st);
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text('Erro ao baixar arquivo: $e')));
    }
  }

  /// Renomeia o arquivo do GED (mobile) — mesma acao ja existente no Web
  /// (ver ged_arquivos_screen.dart._salvarEdicaoNome), via PUT em
  /// ApiLinks.updateArquivo enviando apenas o campo fileName.
  Future<void> _renomearArquivo(
      BuildContext ctx, Map<String, dynamic> item) async {
    final id = item['id'];
    if (id == null) return;
    final nomeAtual = (item['fileName'] ?? item['nome'] ?? '').toString();
    final controller = TextEditingController(text: nomeAtual);
    final novoNome = await showDialog<String>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Renomear arquivo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nome do arquivo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (novoNome == null || novoNome.isEmpty || novoNome == nomeAtual) return;
    if (!ctx.mounted) return;
    try {
      final response = await NetworkCaller().putRequest(
        ApiLinks.updateArquivo(id.toString()),
        {'fileName': novoNome},
      );
      if (!ctx.mounted) return;
      if (response.isSuccess) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Nome atualizado.')),
        );
      } else {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Erro ao renomear: ${response.statusCode}')),
        );
      }
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx)
          .showSnackBar(SnackBar(content: Text('Erro ao renomear: $e')));
    }
  }

  List<FieldConfig> _gedFieldOverrides() {
    return [
      const FieldConfig(
        label: 'ID',
        fieldName: 'id',
        isInForm: false,
        showInCard: false,
        isVisibleByDefault: false,
      ),
      const FieldConfig(
        label: 'Arquivo',
        fieldName: 'file',
        fieldType: FieldType.file,
        isRequired: true,
        fileConfig: FileConfig(
          allowedExtensions: [
            'pdf',
            'doc',
            'docx',
            'jpg',
            'jpeg',
            'png',
            'xls',
            'xlsx',
            'csv',
            'txt',
          ],
          maxFileSize: 10 * 1024 * 1024,
          fileFieldName: 'file',
        ),
      ),
      FieldConfig(
        label: 'Empresa',
        fieldName: 'empresa',
        fieldType: FieldType.dropdown,
        // Fix card #435: filtro "Empresa" nao tinha override no GED mobile
        // e caia no fallback de texto livre (diferente do Web, que ja lista
        // as empresas do usuario logado via dropdown).
        dropdownFutureBuilder: () => _dropdownFromEndpoint(
          ApiLinks.allEmpresas,
          labelKeys: const ['nome', 'razaoSocial', 'label'],
        ),
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      ),
      FieldConfig(
        label: 'Diretorio',
        fieldName: 'diretorio',
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () => _dropdownFromEndpoint(
          ApiLinks.allDiretorios,
          labelKeys: const ['nome', 'descricao', 'label'],
        ),
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      ),
      FieldConfig(
        label: 'Parceiro',
        fieldName: 'parceiro',
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () => _dropdownFromEndpoint(
          ApiLinks.allParceiros,
          labelKeys: const ['nome', 'razaoSocial', 'label'],
        ),
        dropdownValueField: 'value',
        dropdownDisplayField: 'label',
      ),
    ];
  }

  Future<List<Map<String, dynamic>>> _dropdownFromEndpoint(
    String endpoint, {
    required List<String> labelKeys,
  }) async {
    final response = await NetworkCaller().getRequest(endpoint);
    final body = response.body;
    dynamic raw = body;
    if (body is Map) {
      raw = body?['data']?['dados'] ?? body?['data'] ?? body?['content'] ?? body;
    }
    if (!response.isSuccess || raw is! List) return [];

    return raw
        .whereType<Map>()
        .map((item) {
          final map = Map<String, dynamic>.from(item);
          final label = labelKeys.map((key) => map[key]?.toString()).firstWhere(
              (value) => value != null && value.isNotEmpty,
              orElse: () => map['id']?.toString() ?? '');
          return {
            'value': map['id']?.toString() ?? '',
            'label': label,
          };
        })
        .where((item) => item['value']!.isNotEmpty)
        .toList();
  }

  Widget _dynamicGridInline({
    required String telaNome,
    required SecurityMatrix sec,
    required AppScreen screen,
  }) {
    return DynamicGridDynamicScreen(
      key: ValueKey('mobile_dynamic_inline_$telaNome'),
      telaNome: telaNome,
      hasPermission: (action) => _hasPermissionFor(sec, screen, action),
      storageKey: 'mobile_dynamic_$telaNome',
      showAppBar: false,
    );
  }

  /// Tela de Comunicados mobile: apenas o botao "Visualizar comunicado" (customAction).
  /// hasPermission retorna false para tudo — bloqueia todos os botoes automaticos
  /// (server actions, detailScreenBuilder). Os customActions nao sao afetados.
  Widget _comunicadoGridInline({required SecurityMatrix sec}) {
    // Header padrao mobile (UserBannerAppBar) — mesmo cabecalho usado nas
    // demais telas do app, em vez do SimpleAppBar antigo (sem dados do usuario).
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_dynamic_inline_comunicado'),
      telaNome: 'comunicado',
      hasPermission: (action) => false,
      storageKey: 'mobile_dynamic_comunicado',
      customActions: _comunicadoActionsBuilder,
    );
  }

  /// Tela de Chamados mobile: "Visualizar", "Fechar" e "Reabrir" — sem botoes automaticos.
  /// hasPermission retorna false para tudo exceto insert/create — bloqueia server actions
  /// e detailScreenBuilder. Os customActions nao sao afetados pelo hasPermission.
  Widget _chamadoGridInline({required SecurityMatrix sec}) {
    // Header padrao mobile (UserBannerAppBar) — mesmo cabecalho usado nas
    // demais telas do app, em vez do SimpleAppBar antigo (sem dados do usuario).
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_dynamic_inline_chamado'),
      telaNome: 'chamado',
      hasPermission: (action) {
        final lower = action.toLowerCase();
        // Permite criar chamados no mobile
        if (lower == 'insert' || lower == 'create') {
          return _hasPermissionFor(sec, AppScreen.chamados, action);
        }
        // Bloqueia todos os outros botoes automaticos — acoes via customActions
        return false;
      },
      storageKey: 'mobile_dynamic_chamado',
      customActions: () => [
        CustomAction(
          icon: Icons.open_in_new_outlined,
          label: 'Visualizar chamado',
          onPressed: (ctx, item) => _mostrarDetalheChamado(ctx, item),
          isVisible: (_) => true,
        ),
        CustomAction(
          icon: Icons.task_alt_outlined,
          label: 'Fechar chamado',
          onPressed: (ctx, item) {
            final id = item['id'];
            if (id == null) return;
            final chamadoId = id is int ? id : int.tryParse(id.toString()) ?? 0;
            if (chamadoId == 0) return;
            showDialog(
              context: ctx,
              builder: (_) => FecharChamadoDialog(chamadoId: chamadoId),
            );
          },
          isVisible: (item) {
            final status = (item['status'] ?? '').toString().toLowerCase();
            return status != 'fechado' &&
                status != 'cancelado' &&
                status != '3' &&
                status != '4';
          },
        ),
        CustomAction(
          icon: Icons.replay_outlined,
          label: 'Reabrir chamado',
          onPressed: (ctx, item) => _mostrarReabrirChamadoDialog(ctx, item),
          isVisible: (item) {
            final status = (item['status'] ?? '').toString().toLowerCase();
            return status == 'fechado' ||
                status == 'cancelado' ||
                status == '3' ||
                status == '4';
          },
        ),
      ],
    );
  }

  /// Exibe um dialog para digitar o motivo e reabrir o chamado.
  void _mostrarReabrirChamadoDialog(
      BuildContext context, Map<String, dynamic> item) {
    final id = item['id'];
    if (id == null) return;
    final chamadoId = id is int ? id : int.tryParse(id.toString()) ?? 0;
    if (chamadoId == 0) return;
    final motivoCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reabrir chamado'),
        content: TextField(
          controller: motivoCtrl,
          decoration: const InputDecoration(
            labelText: 'Motivo da reabertura',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: GridColors.primary),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final url =
                    '${ApiLinks.baseUrl}/api/chamados/$chamadoId/reabrir';
                await TenantContext.post(url, {'motivo': motivoCtrl.text});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: GridColors.success,
                      content: Text('Chamado reaberto com sucesso'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: GridColors.error,
                      content: Text('Erro ao reabrir chamado: $e'),
                    ),
                  );
                }
              }
            },
            child: const Text('Reabrir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalheChamado(BuildContext context, Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (_, sc) => ListView(
          controller: sc,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: GridColors.divider,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Text(
              item['titulo']?.toString() ?? 'Chamado',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GridColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            _detalheRow('Descricao', item['descricao']),
            _detalheRow('Status', item['status']),
            _detalheRow('Prioridade', item['prioridade']),
            _detalheRow('Setor', item['setor']?['nome'] ?? item['setor']),
            _detalheRow(
                'Abertura', item['dhCreatedAt'] ?? item['dataAbertura']),
            if ((item['motivoFechamento'] ?? '').toString().isNotEmpty)
              _detalheRow('Motivo fechamento', item['motivoFechamento']),
          ],
        ),
      ),
    );
  }

  Widget _detalheRow(String label, dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GridColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  List<BottomNavigationBarItem> _buildNavItems(
    SecurityMatrix sec,
    int selected,
  ) {
    final items = <BottomNavigationBarItem>[];

    void addItem({
      required IconData icon,
      required String label,
    }) {
      final index = items.length;
      final active = index == selected;
      items.add(BottomNavigationBarItem(
        icon: _bottomNavIcon(icon, active: active),
        label: label,
      ));
    }

    // 5 slots para Conta Própria
    addItem(icon: Icons.dashboard_rounded, label: "Início");
    addItem(icon: Icons.account_balance_wallet_rounded, label: "Financeiro");
    addItem(icon: Icons.shopping_cart_rounded, label: "Vendas");
    addItem(icon: Icons.people_alt_rounded, label: "Contatos");

    // Último item = Mais
    addItem(icon: Icons.apps_rounded, label: "Mais");

    return items;
  }

  Widget _bottomNavIcon(IconData icon, {required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      width: active ? 46 : 40,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border:
            active ? Border.all(color: GridColors.secondary, width: 1.2) : null,
      ),
      child: Icon(
        icon,
        size: active ? 21 : 20,
        color: active
            ? GridColors.secondary
            : Colors.white.withValues(alpha: 0.82),
      ),
    );
  }

  bool _hasPermissionFor(
    SecurityMatrix sec,
    AppScreen screen,
    String action,
  ) {
    return switch (action) {
      'insert' || 'create' => sec.canInsert(screen),
      'update' || 'edit' => sec.canUpdate(screen),
      'delete' || 'remove' => sec.canDelete(screen),
      'baixar' || 'baixa' => sec.canBaixar(screen),
      _ => sec.canView(screen),
    };
  }

  static List<CustomAction> _comunicadoActionsBuilder() {
    return [
      CustomAction(
        icon: Icons.visibility_outlined,
        label: 'Visualizar comunicado',
        onPressed: (BuildContext ctx, Map<String, dynamic> item) {
          Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => WindowsComunicadoDetalheScreen(comunicado: item),
          ));
        },
        isVisible: (_) => true,
      ),
    ];
  }

  Future<void> _pushDynamicGrid({
    required String telaNome,
    required SecurityMatrix sec,
    AppScreen? screen,
    String? fetchEndpointOverride,
    String? createEndpointOverride,
    String? updateEndpointOverride,
    String? deleteEndpointOverride,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DynamicGridDynamicScreen(
          key: ValueKey('mobile_dynamic_push_$telaNome'),
          telaNome: telaNome,
          hasPermission: (action) => _hasActionPermission(sec, telaNome, action, screen),
          storageKey: 'mobile_dynamic_$telaNome',
          fetchEndpointOverride: fetchEndpointOverride,
          createEndpointOverride: createEndpointOverride,
          updateEndpointOverride: updateEndpointOverride,
          deleteEndpointOverride: deleteEndpointOverride,
        ),
      ),
    );
  }

  void onMenuOptionSelected(String option, SecurityMatrix sec) {
    Navigator.pop(context); // fecha o bottom sheet do menu
    if (!_canSeeOption(option, sec)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SemAcessoScreen(),
        ),
      );
      return;
    }
    Future<void>? nav;

    switch (option) {
      case "NF-e Série":
      case "Série NF-e":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: const UserBannerAppBar(
                screenTitle: 'Séries NF-e',
                showFilterButton: false,
                showBackButton: true,
              ),
              body: SafeArea(
                child: WebNfeSerieGridScreen(hasPermission: _resolvePermissionForOption(option, sec)),
              ),
            ),
          ),
        );
        break;
      case "Dashboard Fiscal":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              appBar: UserBannerAppBar(
                screenTitle: 'Dashboard Fiscal',
                showFilterButton: false,
                showBackButton: true,
              ),
              body: SafeArea(child: DashboardComercialMercadoriasScreen()),
            ),
          ),
        );
        break;
      case "Dashboard DP":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              appBar: UserBannerAppBar(
                screenTitle: 'Dashboard DP',
                showFilterButton: false,
                showBackButton: true,
              ),
              body: SafeArea(child: DpDashboardScreen()),
            ),
          ),
        );
        break;
      case "Dashboard GME":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicGridDynamicScreen(
              telaNome: 'gme_dashboard',
              hasPermission: _resolvePermissionForOption(option, sec),
              showAppBar: true,
              useUserBannerAppBar: true,
            ),
          ),
        );
        break;
      case "Dashboard Service":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicGridDynamicScreen(
              telaNome: 'service_dashboard',
              hasPermission: _resolvePermissionForOption(option, sec),
              showAppBar: true,
              useUserBannerAppBar: true,
            ),
          ),
        );
        break;
      case "Dashboard Projetos":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicGridDynamicScreen(
              telaNome: 'projeto_dashboard',
              hasPermission: _resolvePermissionForOption(option, sec),
              showAppBar: true,
              useUserBannerAppBar: true,
            ),
          ),
        );
        break;
      case "Dashboard Precificação":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DynamicGridDynamicScreen(
              telaNome: 'precificacao_dashboard',
              hasPermission: _resolvePermissionForOption(option, sec),
              showAppBar: true,
              useUserBannerAppBar: true,
            ),
          ),
        );
        break;

      case "Contas Pagar":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaPagarGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasPagar, action),
            ),
          ),
        );
        break;
      case "Contas Receber":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaReceberGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasReceber, action),
            ),
          ),
        );
        break;
      case "Régua de Cobrança":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              // Header principal padrao (logo, empresa, usuario, alertas e sair).
              // showFilterButton: false — a tela tem cabecalho proprio com
              // Atualizar/Nova etapa/Executar, nao usa a barra de grid.
              // showBackButton: true — tela sempre empilhada via Navigator.push
              // a partir do menu "Mais opções" (fix card #428).
              appBar: UserBannerAppBar(
                screenTitle: 'Régua de Cobrança',
                showFilterButton: false,
                showBackButton: true,
              ),
              body: SafeArea(child: CobrancaAutomaticaScreen()),
            ),
          ),
        );
        break;
      case "Parceiros":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParceiroGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.parceiros, action),
            ),
          ),
        );
        break;
      case "Usuários":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LoginGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.logins, action),
            ),
          ),
        );
        break;
      case "Notas de Serviço (NFS-e)":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileNfseScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfseLista, action),
            ),
          ),
        );
        break;
      case "NF-e Saída":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileNfeGridScreen(
              entrada: false,
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfeSaida, action),
            ),
          ),
        );
        break;
      case "NF-e Entrada":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileNfeGridScreen(
              entrada: true,
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfeEntrada, action),
            ),
          ),
        );
        break;
      case "NFC-e (Cupons)":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileNfceGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfceGrid, action),
            ),
          ),
        );
        break;
      case "Séries NFS-e":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfseSerieScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfseSerie, action),
            ),
          ),
        );
        break;
      case "Config ISS":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NfseConfigScreen()),
        );
        break;
      case "Serviços NFS-e":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NfseServicoScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.nfseServico, action),
            ),
          ),
        );
        break;
      case "Produtos":
        nav = _pushDynamicGrid(
          telaNome: 'produto',
          sec: sec,
          screen: AppScreen.produto,
        );
        break;
      case "Dashboard":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DashboardExecutivoScreen(
              onNavigateToScreen: (idx) => _navigateToScreenIndex(idx, sec),
            ),
          ),
        );
        break;
      case "Dashboard Comercial":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              appBar: UserBannerAppBar(
                screenTitle: 'Dashboard Comercial',
                showFilterButton: false,
                showBackButton: true,
              ),
              body: SafeArea(
                child: DashboardComercialMercadoriasScreen(showAppBar: false),
              ),
            ),
          ),
        );
        break;
      case "Dashboard Financeiro":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DashboardFinanceiroMobileScreen(),
          ),
        );
        break;
      case "Trading":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TradingDashboardScreen()),
        );
        break;
      case "Backtesting":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BacktestScreen(
              repository: BacktestRepository(ApiLinks.baseUrl,
                  headers: TenantContext.jsonHeaders),
            ),
          ),
        );
        break;
      case "PDV":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PdvScreen()),
        );
        break;
      case "Config Fiscal":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ConfigFiscalScreen()),
        );
        break;
      case "CRM/Funil":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CrmPipelineScreen()),
        );
        break;
      case "Obrigacoes":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FiscalAutomationScreen()),
        );
        break;
      case "Contas Bancarias":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ContaBancariaGridScreen(
              hasPermission: (action) =>
                  _hasPermissionFor(sec, AppScreen.contasBancarias, action),
            ),
          ),
        );
        break;
      case "Bater Ponto":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PontoScreen()),
        );
        break;
      case "Funcionários":
        nav = _pushDynamicGrid(
          telaNome: 'funcionario',
          sec: sec,
          screen: AppScreen.funcionarios,
        );
        break;
      case "Mensalidades":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MobileMensalidadeScreen()),
        );
        break;
      case "Alvarás":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MobileAlvaraScreen()),
        );
        break;
      case "Meu Perfil":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MeuPerfilScreen()),
        );
        break;
      case "Controle de Acesso":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RolePermissaoMobileScreen()),
        );
        break;
      case "Permissões Multi-Empresa":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LoginEmpresaAcessoAprovacaoScreen(),
          ),
        );
        break;
      case "Importar Extratos":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MobileExtratoImportacaoScreen(),
          ),
        );
        break;
      // GME
      case "Contratos GME":
        nav = _pushDynamicGrid(telaNome: 'contrato', sec: sec);
        break;
      case "Equipamentos":
        nav = _pushDynamicGrid(telaNome: 'equipamento', sec: sec);
        break;
      case "Ordens de Serviço":
        nav = _pushDynamicGrid(telaNome: 'ordem_servico', sec: sec);
        break;
      case "Planos Manutenção":
        nav = _pushDynamicGrid(telaNome: 'plano_manutencao', sec: sec);
        break;
      case "Horímetro":
        nav = _pushDynamicGrid(telaNome: 'horimetro', sec: sec);
        break;
      case "Histórico Manutenção":
        nav =
            _pushDynamicGrid(telaNome: 'historico_manutencao_screen', sec: sec);
        break;
      case "Técnicos":
        nav = _pushDynamicGrid(telaNome: 'tecnico_manutencao_screen', sec: sec);
        break;
      // Service Desk
      case "SLA":
        nav = _pushDynamicGrid(telaNome: 'sla_screen', sec: sec);
        break;
      case "Filas Atendimento":
        nav = _pushDynamicGrid(telaNome: 'fila_atendimento_screen', sec: sec);
        break;
      case "Categorias Chamado":
        nav = _pushDynamicGrid(telaNome: 'categoria_chamado_screen', sec: sec);
        break;
      case "Avaliações":
        nav = _pushDynamicGrid(telaNome: 'chamado_avaliacao_screen', sec: sec);
        break;
      // Projetos
      case "Projetos":
        nav = _pushDynamicGrid(telaNome: 'projeto', sec: sec);
        break;
      case "Etapas Projeto":
        nav = _pushDynamicGrid(telaNome: 'projeto_etapa', sec: sec);
        break;
      case "Recursos Projeto":
        nav = _pushDynamicGrid(telaNome: 'projeto_recurso', sec: sec);
        break;
      case "Apontamentos":
        nav =
            _pushDynamicGrid(telaNome: 'projeto_apontamento', sec: sec);
        break;
      case "Medições":
        nav = _pushDynamicGrid(telaNome: 'projeto_medicao', sec: sec);
        break;
      case "Cargos/Recursos":
        nav = _pushDynamicGrid(telaNome: 'cargo_recurso', sec: sec);
        break;
      // Precificação
      case "Precificações":
        nav = _pushDynamicGrid(telaNome: 'precificacao', sec: sec);
        break;
      case "Custos Diretos":
        nav = _pushDynamicGrid(
            telaNome: 'custo_direto', sec: sec);
        break;
      case "Mão de Obra":
        nav = _pushDynamicGrid(
            telaNome: 'mao_de_obra', sec: sec);
        break;
      case "Serviços Precificação":
        nav =
            _pushDynamicGrid(telaNome: 'precificacao_servico', sec: sec);
        break;
      case "Condições Pagamento":
        nav = _pushDynamicGrid(
            telaNome: 'condicao_pagamento', sec: sec);
        break;
      case "Propostas Comerciais":
        nav = _pushDynamicGrid(telaNome: 'proposta_comercial', sec: sec);
        break;
      case "Agendar NFe Recorrente":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgendamentoModuleScreen()),
        );
        break;
      
      // Comercial
      case "Planos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePlanoGridScreen()));
        break;
      case "Tipos de Parceiro":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTipoParceiroGridScreen()));
        break;
      case "Serviços Contratados":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileServicoContratadoGridScreen()));
        break;
      case "Módulos de Serviço":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileModuloServicoGridScreen()));
        break;
      case "Catálogo de Produtos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCatalagoProdutoGridScreen()));
        break;
      case "Unidades de Medida":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileUnidadeMedidaGridScreen()));
        break;
      case "Orçamentos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileOrcamentoGridScreen()));
        break;
      case "Pedidos de Venda":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePedidoVendaGridScreen()));
        break;
      case "Pedidos de Compra":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePedidoCompraGridScreen()));
        break;
      case "Pedidos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePedidoGridScreen()));
        break;
      case "Aprovação de Compras":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAprovacaoCompraScreen()));
        break;
      case "Tabela de Preços":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTabelaPrecoScreen()));
        break;
      case "Devoluções":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDevolucaoGridScreen()));
        break;
      case "Fornecedores":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileFornecedorGridScreen()));
        break;
      case "Reserva de Estoque":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileReservaEstoqueScreen()));
        break;
      case "Multi-depósito":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDepositoScreen()));
        break;
      case "Tickets":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTicketGridScreen()));
        break;
      case "Cotação de Frete":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCotacaoFreteGridScreen()));
        break;
      case "Dividendos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDividendoGridScreen()));
        break;
      case "Ordens":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileOrderGridScreen()));
        break;
      case "Classificação":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileClassificacaoGridScreen()));
        break;
      case "Departamentos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDepartamentoGridScreen()));
        break;
      case "Cargos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCargoGridScreen()));
        break;

      // Fiscal
      case "NF-e Finalidade":
        nav = _pushDynamicGrid(telaNome: 'nfe_finalidade', sec: sec);
        break;
      case "NF-e Tipo Operação":
        nav = _pushDynamicGrid(telaNome: 'nfe_tipo_operacao', sec: sec);
        break;
      case "Importar XML NF-e":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileNfeImportXmlScreen()));
        break;
      case "Importar NF-e CSV":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileNfeImportScreen()));
        break;
      case "Importar XML NFS-e":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileNfseImportXmlScreen()));
        break;
      case "Consulta DF-e":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileConsultaDfeScreen()));
        break;
      case "Manifestação Destinatário":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileManifestacaoDestinatarioScreen()));
        break;
      case "Cancelamento e CC-e":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCancelamentoCceScreen()));
        break;
      case "Regime Tributário":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRegimeGridScreen()));
        break;
      case "Regras Fiscais":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MobileRegraFiscalScreen(
              hasPermission: _resolvePermissionForOption(option, sec),
            ),
          ),
        );
        break;
      case "Obrigações Fiscais":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileObrigacaoFiscalGridScreen()));
        break;
      case "Calendário Tributário":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCalendarioTributarioScreen()));
        break;

      // Financeiro
      case "Formas de Pagamento":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileFormaPagamentoGridScreen()));
        break;
      case "Centros de Custo":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCentroCustoGridScreen()));
        break;
      case "Categorias Financeiras":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCategoriaFinanceiraGridScreen()));
        break;
      case "Lançamentos Financeiros":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileLancamentoFinanceiroGridScreen()));
        break;
      case "Conciliação Bancária":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileConciliacaoScreen()));
        break;
      case "Rateio Financeiro":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRateioFinanceiroScreen()));
        break;
      case "Baixa Automática":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileBaixaAutomaticaScreen()));
        break;
      case "Renegociação":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRenegociacaoScreen()));
        break;
      case "Cobrança":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCobrancaScreen()));
        break;
      case "Cobrança Automática":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(
              appBar: UserBannerAppBar(
                screenTitle: 'Cobrança Automática',
                showFilterButton: false,
                showBackButton: true,
              ),
              body: SafeArea(child: CobrancaAutomaticaScreen()),
            ),
          ),
        );
        break;
      case "Dashboard Mensalidades":
        nav = Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MobileWebDashboardMensalidadeScreen(),
          ),
        );
        break;
      case "DRE Gerencial":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDreScreen()));
        break;
      case "Envio EDI (Remessa)":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCnabRemessaScreen()));
        break;
      case "Kanban de Pagamentos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileKanbanPagamentosScreen()));
        break;
      case "Aprovação de Pagamentos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAprovacaoPagamentosScreen()));
        break;
      case "Calendário de Guias":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCalendarioGuiasGridScreen()));
        break;
      case "Importar Boletos (Lote)":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileBoletoImportacaoLoteScreen()));
        break;
      case "Integrações Financeiras":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileIntegracoesFinanceirasScreen()));
        break;

      // Departamento Pessoal
      case "Solicitar Ajuste":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const PontoSolicitacaoScreen()));
        break;
      case "Ajuste de Ponto":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePontoAjusteScreen()));
        break;
      case "Feriados":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileFeriadoGridScreen()));
        break;
      case "Setores":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileSetorGridScreen()));
        break;
      case "Horários Funcionário":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileHorarioFuncGridScreen()));
        break;
      case "Relatórios DP/RH":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RelatorioPontoScreen()),
        );
        break;

      // Contábil & IA
      case "Plano de Contas":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileContaContabilGridScreen()));
        break;
      case "Lançamentos Contábeis":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileLancamentoContabilGridScreen()));
        break;
      case "Balancete":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileBalanceteScreen()));
        break;
      case "Fechamento de Período":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileFechamentoPeriodoScreen()));
        break;
      case "Dashboard IA":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAiDashboardScreen()));
        break;
      case "Assistente IA":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAiAssistenteScreen()));
        break;

      // Suporte & Comunicação
      case "Alertas":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAlertaAlunoGridScreen()));
        break;
      case "Diretórios":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDiretorioGridScreen()));
        break;
      case "Notícias":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileNoticiasGridScreen()));
        break;
      case "Kanban Chamados":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileKanbanChamadosScreen()));
        break;
      case "Kanban Chat":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileKanbanChatScreen()));
        break;
      case "Instagram Monitor":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileInstagramMonitorScreen()));
        break;

      // Academia & Saúde
      case "Academias":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAcademiaGridScreen()));
        break;
      case "Alimentos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAlimentoGridScreen()));
        break;
      case "Dietas":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileDietaGridScreen()));
        break;
      case "Exercícios":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileExercicioGridScreen()));
        break;
      case "Grupos Musculares":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileGrupoMuscularGridScreen()));
        break;
      case "Medicamentos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileMedicamentoGridScreen()));
        break;
      case "Modalidades":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileModalidadeGridScreen()));
        break;
      case "Objetivos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileObjetivoGridScreen()));
        break;
      case "Personais":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePersonalGridScreen()));
        break;
      case "Suplementos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileSuplementoGridScreen()));
        break;
      case "Treinos":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTreinoGridScreen()));
        break;
      case "Avaliação Física":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAvaliacaoFisicaGridScreen()));
        break;
      case "Anamnese":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAnamneseScreen()));
        break;

      // Trading
      case "Sinais de Mercado":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingSinaisScreen()));
        break;
      case "Oportunidades":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingOportunidadesScreen()));
        break;
      case "Watchlist":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingWatchlistScreen()));
        break;
      case "Alertas de Preço":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingAlertasScreen()));
        break;
      case "Operações Assistidas":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingOperacoesScreen()));
        break;
      case "Configuração da Corretora":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingCorretoraScreen()));
        break;
      case "Minha Carteira":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileTradingCarteiraScreen()));
        break;

      // Sistema
      case "Aplicativo":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileAplicativoScreen()));
        break;
      case "Empresas":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileEmpresaGridScreen()));
        break;
      case "Roles":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileRoleGridScreen()));
        break;
      case "Configurações Admin":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileConfiguracoesAdminScreen()));
        break;
      case "Configurações Sistema":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileConfiguracoesSistemaScreen()));
        break;
      case "Editor de Telas":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileEditorTelasScreen()));
        break;
      case "Cadastro de Empresa":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCadastroEmpresaWizard()));
        break;
      case "Importação Fiscal Automação":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileImportacaoFiscalAutomacaoScreen()));
        break;
      case "Certificado Digital":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileCertificadoDigitalScreen()));
        break;
      case "Solicitações de Acesso":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileSolicitacoesAcessoScreen()));
        break;
      case "Query Builder":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileQueryBuilderWindowScreen()));
        break;
      case "Sessões":
        nav = Navigator.push(context, MaterialPageRoute(builder: (_) => const MobileSessoesScreen()));
        break;
      case "Teste de Endpoints":
        nav = Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MobileSystemTestScreen()),
        );
        break;

      case "Voltar":
        return;
      case "Sair":
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sair do aplicativo'),
            content: const Text('Deseja encerrar a sessão?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: GridColors.primary,
                    foregroundColor: Colors.white),
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthUtility.clearUserInfo();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        return; // logout não reabre o menu
    }

    // Quando o usuário pressionar voltar em qualquer tela do menu "Mais",
    // reabrir o menu automaticamente.
    nav?.then((_) {
      if (mounted) _showMenuOptions(context, sec);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final screens = _buildScreens(sec);

    final safeIndex = selectedIndex.clamp(0, screens.length - 1);
    final navItems = _buildNavItems(sec, safeIndex);

    // BottomNavigationBar exige no mínimo 2 itens
    if (navItems.length < 2) {
      return const SemAcessoScreen();
    }

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      body: Stack(
        children: [
          IndexedStack(
            index: safeIndex,
            children: screens,
          ),
          const AppLoggerOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: GridColors.primary,
          border: Border(
            top: BorderSide(color: GridColors.primaryDark, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: GridColors.primary,
          currentIndex: safeIndex,
          unselectedItemColor: Colors.white.withValues(alpha: 0.82),
          selectedItemColor: Colors.white,
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.82),
          ),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          onTap: (int index) {
            // Índice fixo: 0=Início, 1=Financeiro, 2=Vendas, 3=Contatos, 4=Mais
            if (index == 4) {
              // Último slot = Mais → abre bottom sheet agrupado
              _showMenuOptions(context, sec);
            } else {
              setState(() => selectedIndex = index);
            }
          },
          items: navItems,
        ),
      ),
    );
  }

  void _showMenuOptions(BuildContext context, SecurityMatrix sec) {
    final contratados = ModuloAccess.modulosContratados;
    final temComercial = _temModuloContratado(contratados, const ['Comercial']);
    final temNfce = _temModuloContratado(contratados, const [
      'NFC-e',
      'Fiscal / NFC-e',
      'Fiscal e NF-e',
      'Notas Fiscais',
    ]);
    final temNfse = _temModuloContratado(contratados, const ['NFS-e', 'NFSe']);
    final temFinanceiro = _temModuloContratado(contratados, const [
      'Financeiro',
      'Financeiro Limitado',
      'Financeiro avançado',
      'Financeiro avancado',
    ]);
    final temDp = _temModuloContratado(contratados, const [
      'Departamento Pessoal',
      'RH',
      'Recursos Humanos',
    ]);
    final temContabil = _temModuloContratado(contratados, const ['Contábil', 'Contabil']);
    final temAcademia = _temModuloContratado(contratados, const ['Academia']);
    final temTrading = _temModuloContratado(contratados, const [
      'Bolsa de Valores',
      'Trading',
      'Investimentos',
    ]);
    final temSuporte = _temModuloContratado(contratados, const [
      'Chamados',
      'Chat',
      'Comunicados',
      'GED',
    ]);
    final temFinanceiroAvancado = _temModuloContratado(contratados, const [
      'Financeiro avançado',
      'Financeiro avancado',
    ]);
    final podeVerConfigIss =
        _canSeeOption('Config ISS', sec) ||
        sec.canView(AppScreen.configFiscal) ||
        sec.canView(AppScreen.nfse);

    // Define os grupos de módulos com seus itens (gateados por permissão)
    final modulos = <_ModuloGroup>[
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temComercial || temNfce)
        _ModuloGroup(
          'Comercial',
          Icons.business,
          [
            if (temNfce && _canSeeOption('PDV', sec))
              _MoreMenuAction(Icons.point_of_sale, 'PDV'),
            if ((temComercial || temNfce) && _canSeeOption('Produtos', sec))
              _MoreMenuAction(Icons.inventory, 'Produtos'),
            _MoreMenuAction(Icons.people, 'Parceiros'),
            _MoreMenuAction(Icons.local_shipping, 'Fornecedores'),
            _MoreMenuAction(Icons.card_membership, 'Planos'),
            _MoreMenuAction(Icons.badge, 'Tipos de Parceiro'),
            _MoreMenuAction(Icons.handshake, 'Serviços Contratados'),
            _MoreMenuAction(Icons.view_module, 'Módulos de Serviço'),
            _MoreMenuAction(Icons.menu_book, 'Catálogo de Produtos'),
            _MoreMenuAction(Icons.straighten, 'Unidades de Medida'),
            _MoreMenuAction(Icons.request_quote, 'Orçamentos'),
            _MoreMenuAction(Icons.shopping_cart, 'Pedidos de Venda'),
            _MoreMenuAction(Icons.shopping_bag, 'Pedidos de Compra'),
            _MoreMenuAction(Icons.receipt, 'Pedidos'),
            _MoreMenuAction(Icons.check_circle_outline, 'Aprovação de Compras'),
            _MoreMenuAction(Icons.price_change, 'Tabela de Preços'),
            _MoreMenuAction(Icons.assignment_return, 'Devoluções'),
            _MoreMenuAction(Icons.warehouse, 'Reserva de Estoque'),
            _MoreMenuAction(Icons.store, 'Multi-depósito'),
            _MoreMenuAction(Icons.trending_up, 'Dashboard Comercial'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temFinanceiro)
        _ModuloGroup(
          'Financeiro',
          Icons.account_balance,
          [
            _MoreMenuAction(Icons.payments, 'Contas Pagar'),
            _MoreMenuAction(Icons.account_balance_wallet, 'Contas Receber'),
            _MoreMenuAction(Icons.account_balance, 'Contas Bancarias'),
            _MoreMenuAction(Icons.credit_card, 'Formas de Pagamento'),
            _MoreMenuAction(Icons.pie_chart, 'Centros de Custo'),
            _MoreMenuAction(Icons.category, 'Categorias Financeiras'),
            _MoreMenuAction(Icons.swap_horiz, 'Lançamentos Financeiros'),
            _MoreMenuAction(Icons.upload_file, 'Importar Extratos'),
            _MoreMenuAction(Icons.sync_alt, 'Conciliação Bancária'),
            _MoreMenuAction(Icons.call_split, 'Rateio Financeiro'),
            _MoreMenuAction(Icons.check_box, 'Baixa Automática'),
            _MoreMenuAction(Icons.edit_calendar, 'Renegociação'),
            _MoreMenuAction(Icons.warning_amber, 'Cobrança'),
            if (temFinanceiroAvancado)
              _MoreMenuAction(Icons.notifications_active, 'Régua de Cobrança'),
            _MoreMenuAction(Icons.bar_chart, 'DRE Gerencial'),
            _MoreMenuAction(Icons.send, 'Envio EDI (Remessa)'),
            _MoreMenuAction(Icons.view_kanban, 'Kanban de Pagamentos'),
            _MoreMenuAction(Icons.verified, 'Aprovação de Pagamentos'),
            _MoreMenuAction(Icons.auto_mode, 'Cobrança Automática'),
            _MoreMenuAction(Icons.receipt, 'Mensalidades'),
            _MoreMenuAction(Icons.pie_chart, 'Dashboard Mensalidades'),
            _MoreMenuAction(Icons.event_note, 'Calendário de Guias'),
            _MoreMenuAction(Icons.receipt_long, 'Importar Boletos (Lote)'),
            _MoreMenuAction(Icons.integration_instructions, 'Integrações Financeiras'),
            _MoreMenuAction(Icons.bar_chart, 'Dashboard'),
            _MoreMenuAction(Icons.account_balance_wallet, 'Dashboard Financeiro'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temNfce)
        _ModuloGroup(
          'Fiscal',
          Icons.receipt,
          [
            _MoreMenuAction(Icons.file_upload, 'NF-e Saída'),
            _MoreMenuAction(Icons.file_download, 'NF-e Entrada'),
            _MoreMenuAction(Icons.receipt_long, 'NFC-e (Cupons)'),
            _MoreMenuAction(Icons.tag, 'NF-e Série'),
            _MoreMenuAction(Icons.filter_list, 'NF-e Finalidade'),
            _MoreMenuAction(Icons.alt_route, 'NF-e Tipo Operação'),
            _MoreMenuAction(Icons.file_present, 'Importar XML NF-e'),
            _MoreMenuAction(Icons.table_view, 'Importar NF-e CSV'),
            _MoreMenuAction(Icons.search, 'Consulta DF-e'),
            _MoreMenuAction(Icons.assignment_turned_in, 'Manifestação Destinatário'),
            _MoreMenuAction(Icons.cancel, 'Cancelamento e CC-e'),
            if (temNfce)
              _MoreMenuAction(Icons.event_repeat, 'Agendar NFe Recorrente'),
            _MoreMenuAction(Icons.policy, 'Regime Tributário'),
            _MoreMenuAction(Icons.rule, 'Regras Fiscais'),
            _MoreMenuAction(Icons.fact_check, 'Obrigações Fiscais'),
            _MoreMenuAction(Icons.calendar_month, 'Calendário Tributário'),
            _MoreMenuAction(Icons.bar_chart, 'Dashboard Fiscal'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temNfse)
        _ModuloGroup(
          'NFS-e',
          Icons.description,
          [
            if (temNfse) ...[
              _MoreMenuAction(Icons.file_copy, 'Notas de Serviço (NFS-e)'),
              _MoreMenuAction(Icons.tag, 'Séries NFS-e'),
              _MoreMenuAction(Icons.work, 'Serviços NFS-e'),
              _MoreMenuAction(Icons.upload_file, 'Importar XML NFS-e'),
            ],
            if (temNfse && podeVerConfigIss)
              _MoreMenuAction(Icons.settings, 'Config ISS'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temDp)
        _ModuloGroup(
          'Departamento Pessoal',
          Icons.badge,
          [
            if (_canSeeOption('Bater Ponto', sec))
              _MoreMenuAction(Icons.access_time, 'Bater Ponto'),
            _MoreMenuAction(Icons.people_outline, 'Funcionários'),
            _MoreMenuAction(Icons.edit_calendar, 'Solicitar Ajuste'),
            _MoreMenuAction(Icons.schedule, 'Ajuste de Ponto'),
            _MoreMenuAction(Icons.event_busy, 'Feriados'),
            _MoreMenuAction(Icons.domain, 'Setores'),
            _MoreMenuAction(Icons.timelapse, 'Horários Funcionário'),
            _MoreMenuAction(Icons.badge, 'Dashboard DP'),
            _MoreMenuAction(Icons.analytics, 'Relatórios DP/RH'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temContabil)
        _ModuloGroup(
          'Contábil & IA',
          Icons.account_tree,
          [
            _MoreMenuAction(Icons.account_tree, 'Plano de Contas'),
            _MoreMenuAction(Icons.history_edu, 'Lançamentos Contábeis'),
            _MoreMenuAction(Icons.scale, 'Balancete'),
            _MoreMenuAction(Icons.lock_clock, 'Fechamento de Período'),
            _MoreMenuAction(Icons.smart_toy, 'Dashboard IA'),
            _MoreMenuAction(Icons.psychology, 'Assistente IA'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temSuporte)
        _ModuloGroup(
          'Suporte & Comunicação',
          Icons.support_agent,
          [
            _MoreMenuAction(Icons.notifications, 'Alertas'),
            _MoreMenuAction(Icons.folder_shared, 'Diretórios'),
            _MoreMenuAction(Icons.newspaper, 'Notícias'),
            _MoreMenuAction(Icons.view_kanban, 'Kanban Chamados'),
            _MoreMenuAction(Icons.chat, 'Kanban Chat'),
            _MoreMenuAction(Icons.camera_alt, 'Instagram Monitor'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temAcademia)
        _ModuloGroup(
          'Academia & Saúde',
          Icons.fitness_center,
          [
            _MoreMenuAction(Icons.fitness_center, 'Academias'),
            _MoreMenuAction(Icons.restaurant, 'Alimentos'),
            _MoreMenuAction(Icons.menu_book, 'Dietas'),
            _MoreMenuAction(Icons.directions_run, 'Exercícios'),
            _MoreMenuAction(Icons.accessibility_new, 'Grupos Musculares'),
            _MoreMenuAction(Icons.medication, 'Medicamentos'),
            _MoreMenuAction(Icons.sports, 'Modalidades'),
            _MoreMenuAction(Icons.track_changes, 'Objetivos'),
            _MoreMenuAction(Icons.person, 'Personais'),
            _MoreMenuAction(Icons.local_pharmacy, 'Suplementos'),
            _MoreMenuAction(Icons.sports_gymnastics, 'Treinos'),
            _MoreMenuAction(Icons.monitor_weight, 'Avaliação Física'),
            _MoreMenuAction(Icons.assignment, 'Anamnese'),
          ],
        ),
      if (!ModuloAccess.hasModulosConfigurados || sec.isMaster || temTrading)
        _ModuloGroup(
          'Bolsa de Valores',
          Icons.show_chart,
          [
            _MoreMenuAction(Icons.candlestick_chart, 'Trading'),
            _MoreMenuAction(Icons.history, 'Backtesting'),
            _MoreMenuAction(Icons.trending_up, 'Sinais de Mercado'),
            _MoreMenuAction(Icons.lightbulb, 'Oportunidades'),
            _MoreMenuAction(Icons.remove_red_eye, 'Watchlist'),
            _MoreMenuAction(Icons.alarm, 'Alertas de Preço'),
            _MoreMenuAction(Icons.play_circle, 'Operações Assistidas'),
            _MoreMenuAction(Icons.settings_input_component, 'Configuração da Corretora'),
            _MoreMenuAction(Icons.account_balance_wallet, 'Minha Carteira'),
          ],
        ),
      if (sec.isMaster || contratados.contains('GME'))
        _ModuloGroup(
          'GME',
          Icons.precision_manufacturing,
          [
            if (sec.isMaster || contratados.contains('GME')) ...[
              _MoreMenuAction(Icons.bar_chart, 'Dashboard GME'),
              _MoreMenuAction(Icons.description, 'Contratos GME'),
              _MoreMenuAction(Icons.build, 'Equipamentos'),
              _MoreMenuAction(Icons.assignment, 'Ordens de Serviço'),
              _MoreMenuAction(Icons.event_note, 'Planos Manutenção'),
              _MoreMenuAction(Icons.timer, 'Horímetro'),
              _MoreMenuAction(Icons.history, 'Histórico Manutenção'),
              _MoreMenuAction(Icons.engineering, 'Técnicos'),
            ],
          ],
        ),
      if (sec.isMaster || contratados.contains('Service Desk') || contratados.contains('Service'))
        _ModuloGroup(
          'Service Desk',
          Icons.support_agent,
          [
            if (sec.isMaster || contratados.contains('Service Desk') || contratados.contains('Service')) ...[
              _MoreMenuAction(Icons.bar_chart, 'Dashboard Service'),
              _MoreMenuAction(Icons.timer, 'SLA'),
              _MoreMenuAction(Icons.queue, 'Filas Atendimento'),
              _MoreMenuAction(Icons.category, 'Categorias Chamado'),
              _MoreMenuAction(Icons.star, 'Avaliações'),
            ],
          ],
        ),
      if (sec.isMaster || contratados.contains('Projetos'))
        _ModuloGroup(
          'Projetos',
          Icons.folder_special,
          [
            if (sec.isMaster || contratados.contains('Projetos')) ...[
              _MoreMenuAction(Icons.bar_chart, 'Dashboard Projetos'),
              _MoreMenuAction(Icons.folder, 'Projetos'),
              _MoreMenuAction(Icons.list_alt, 'Etapas Projeto'),
              _MoreMenuAction(Icons.people, 'Recursos Projeto'),
              _MoreMenuAction(Icons.edit_note, 'Apontamentos'),
              _MoreMenuAction(Icons.straighten, 'Medições'),
              _MoreMenuAction(Icons.work, 'Cargos/Recursos'),
            ],
          ],
        ),
      if (sec.isMaster || contratados.contains('Precificação') || contratados.contains('Precificacao'))
        _ModuloGroup(
          'Precificação',
          Icons.calculate,
          [
            if (sec.isMaster || contratados.contains('Precificação') || contratados.contains('Precificacao')) ...[
              _MoreMenuAction(Icons.bar_chart, 'Dashboard Precificação'),
              _MoreMenuAction(Icons.request_quote, 'Precificações'),
              _MoreMenuAction(Icons.attach_money, 'Custos Diretos'),
              _MoreMenuAction(Icons.person, 'Mão de Obra'),
              _MoreMenuAction(
                  Icons.miscellaneous_services, 'Serviços Precificação'),
              _MoreMenuAction(Icons.payment, 'Condições Pagamento'),
              _MoreMenuAction(Icons.description, 'Propostas Comerciais'),
            ],
          ],
        ),
      _ModuloGroup(
        'Sistema',
        Icons.settings,
        [
          _MoreMenuAction(Icons.apps, 'Aplicativo'),
          _MoreMenuAction(Icons.business, 'Empresas'),
          _MoreMenuAction(Icons.manage_accounts, 'Usuários'),
          _MoreMenuAction(Icons.security, 'Roles'),
          _MoreMenuAction(Icons.verified_user, 'Alvarás'),
          _MoreMenuAction(Icons.admin_panel_settings, 'Configurações Admin'),
          _MoreMenuAction(Icons.settings_applications, 'Configurações Sistema'),
          _MoreMenuAction(Icons.edit, 'Editor de Telas'),
          _MoreMenuAction(Icons.domain_add, 'Cadastro de Empresa'),
          _MoreMenuAction(Icons.auto_fix_high, 'Importação Fiscal Automação'),
          _MoreMenuAction(Icons.vpn_key, 'Certificado Digital'),
          _MoreMenuAction(Icons.approval, 'Solicitações de Acesso'),
          _MoreMenuAction(Icons.switch_account, 'Permissões Multi-Empresa'),
          _MoreMenuAction(Icons.terminal, 'Query Builder'),
          _MoreMenuAction(Icons.devices, 'Sessões'),
          _MoreMenuAction(Icons.account_circle, 'Meu Perfil'),
          _MoreMenuAction(Icons.lock, 'Controle de Acesso'),
          if (temNfce) _MoreMenuAction(Icons.settings, 'Config Fiscal'),
          _MoreMenuAction(Icons.health_and_safety, 'Teste de Endpoints'),
          _MoreMenuAction(Icons.exit_to_app, 'Sair', isDestructive: true),
        ],
      ),
    ];

    // Filtra apenas grupos com itens visíveis
    final gruposVisiveis = modulos
        .map((g) => _ModuloGroup(
              g.nome,
              g.icon,
              g.items.where((i) => _canSeeOption(i.title, sec)).toList(),
            ))
        .where((g) => g.items.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: GridColors.card,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: GridColors.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Voltar no topo (antes so tinha embaixo, exigindo rolar tudo)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.arrow_back, size: 20),
                    label: const Text('Voltar'),
                    style: TextButton.styleFrom(
                      foregroundColor: GridColors.textSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: GridColors.secondarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.apps_rounded,
                        color: GridColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mais opções',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: GridColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Acesse os módulos do sistema',
                            style: TextStyle(
                              fontSize: 12,
                              color: GridColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                      color: GridColors.textMuted,
                      tooltip: 'Fechar',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Grupos do módulo contratado — com badge "contratado"
                ...gruposVisiveis.map((grupo) {
                  final contratado = contratados.contains(grupo.nome);
                  return _buildModuloGroup(
                    grupo,
                    contratado,
                    sec,
                  );
                }),
                const SizedBox(height: 8),
                // Pedido do usuario: mostrar a versao instalada (mesma que
                // sobe pro Google Play via fastlane -- versionName+versionCode
                // do AndroidManifest, lidos em runtime via package_info_plus)
                // pra facilitar confirmar se o app ja atualizou depois de um
                // fix, sem precisar ir em Configuracoes do Android.
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final info = snapshot.data;
                    if (info == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Versão ${info.version} (build ${info.buildNumber})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.arrow_downward_rounded),
                    label: const Text('Fechar menu'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _temModuloContratado(List<String> contratados, List<String> aliases) {
    return aliases.any(contratados.contains);
  }

  Widget _buildModuloGroup(
    _ModuloGroup grupo,
    bool contratado,
    SecurityMatrix sec,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
          child: Row(
            children: [
              Icon(grupo.icon,
                  size: 16,
                  color:
                      contratado ? GridColors.secondary : GridColors.textMuted),
              const SizedBox(width: 8),
              Text(
                grupo.nome,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: contratado
                      ? GridColors.textSecondary
                      : GridColors.textMuted,
                ),
              ),
              if (contratado) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: GridColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'contratado',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: GridColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: grupo.items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (_, index) {
            final item = grupo.items[index];
            return _menuItemGrid(
              item.icon,
              item.title,
              sec,
              isDestructive: item.isDestructive,
            );
          },
        ),
        const Divider(height: 20),
      ],
    );
  }

  Widget _menuItemGrid(
    IconData icon,
    String title,
    SecurityMatrix sec, {
    bool isDestructive = false,
  }) {
    final Color accent =
        isDestructive ? GridColors.primary : GridColors.secondary;
    final Color background =
        isDestructive ? GridColors.primarySoft : GridColors.secondarySoft;

    return InkWell(
      onTap: () => onMenuOptionSelected(title, sec),
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        decoration: BoxDecoration(
          color: GridColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GridColors.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuAction {
  final IconData icon;
  final String title;
  final bool isDestructive;

  const _MoreMenuAction(
    this.icon,
    this.title, {
    this.isDestructive = false,
  });
}

class _ModuloGroup {
  final String nome;
  final IconData icon;
  final List<_MoreMenuAction> items;

  const _ModuloGroup(this.nome, this.icon, this.items);
}

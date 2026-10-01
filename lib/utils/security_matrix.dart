// lib/utils/security_matrix.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;
import '../models/auth_utility.dart';
import '../models/login_model.dart';
import '../services/permission_service.dart';
import '../utils/api_links.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. Telas / recursos
// ─────────────────────────────────────────────────────────────────────────────
enum AppScreen {
  // Mobile – Bottom Nav
  calendario, chat, comunicados, chamados, ged,
  // Mobile – Menu Mais
  contasPagar, contasReceber, parceiros, dashboard, contasBancarias,
  ponto, funcionarios,
  // Dashboard widgets
  dashKpis, dashFinanceCards, dashFluxoDiario, dashTendenciaFinanceira,
  dashDistribuicaoClientes, dashComparativoTrimestral, dashAlertas,
  dashChamadosCards, dashChamadosPie, dashTendenciaChamados,
  dashChatsLinha, dashChatsDiario, dashSaldoContas, dashEvolucaoSaldos,
  // Web / Windows – Sidebar
  noticias, logins, cotacao, trading, comprar, aplicativo, vender, perfil,
  regimeTributario, alimentos, dietas, empresas, exames, exercicios,
  gruposMusculares, medicamentos, mensalidades, modalidades, objetivos,
  personais, planos, roles, rolesPermissoes, setores, suplementos,
  formasPagamento, diretorios, arquivos, obrigacoesFiscais,
  // Novas telas
  pedidos, configuracoesAdmin, contaBancaria, feriados,
  kanbanChamados, nfeEntrada, nfeSaida,
  // Ponto web
  pontoWeb, solicitacaoAjustePonto, ajustePonto,
  // Admin sistema — só ROLE_SYSTEM
  configSistema,
  // Novas telas cadastro
  tipoParceiro, servicoContratado, moduloServico,
  // Produto
  produto,
  // Cadastros auxiliares NF-e e produto
  unidadeMedida, catalogoProduto, nfeSerie, pdvNfce, configFiscal,
  // NFS-e (Notas Fiscais de Servico — modulo separado de Notas Fiscais NF-e)
  nfse,
  nfseLista, nfseSerie, nfseServico,
  // Dashboards por área (Fase 171 — fundação)
  dashAtendimentoArea, dashFinanceiroArea, dashComercialArea,
  dashDpArea, dashFiscalArea,
  // Chat Kanban
  chatKanban,
  // Dashboard de mensalidades do escritorio
  dashMensalidadeArea,
  // Importação de boletos em lote
  boletoImportacaoLote,
  // Módulo Financeiro Avançado (gating helper)
  cobranca, dreGerencial, conciliacaoBancaria, importarExtrato,
  lancamentosFinanceiros, integracoesFinanceiras,
  // Compras e Estoque
  fornecedores, tabelaPreco, devolucoes, aprovacaoCompra,
  reservaEstoque, multiDeposito,
  // IA / Análise Inteligente
  aiDashboard, aiAssistente,
  // Módulo Contábil
  lancamentoContabil, balancete, fechamentoPeriodo,
  // Alvarás
  alvaras,
  // NFC-e Cupons (grid de cupons fiscais eletrônicos)
  nfceGrid,
  // CNAB / Remessa EDI
  cnabRemessa,
  // Paridade Web/Windows/Mobile
  regraFiscal, cobrancaAutomatica, aprovacaoPagamentos, sistemaTest,
  rateioFinanceiro, baixaAutomatica, renegociacao, contaContabil, relatorioDpRh,
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. Ações
// ─────────────────────────────────────────────────────────────────────────────
enum AppAction { view, insert, update, delete, baixar }

// ─────────────────────────────────────────────────────────────────────────────
// 3. Perfis (mantidos para compatibilidade com código legado)
// ─────────────────────────────────────────────────────────────────────────────
enum UserProfile {
  system, escritorio, gerente, financeiro, faturista, ponto, semAcesso,
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. Mapeamento role.key → UserProfile
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, UserProfile> _roleKeyToProfile = {
  'ROLE_SYSTEM':     UserProfile.system,
  'ROLE_ESCRITORIO': UserProfile.escritorio,
  'ROLE_GERENTE':    UserProfile.gerente,
  'ROLE_FINANCEIRO': UserProfile.financeiro,
  'ROLE_FATURISTA':  UserProfile.faturista,
  'ROLE_PONTO':      UserProfile.ponto,
};

// ─────────────────────────────────────────────────────────────────────────────
// 5. Atalhos
// ─────────────────────────────────────────────────────────────────────────────
const _all         = {AppAction.view, AppAction.insert, AppAction.update, AppAction.delete};
const _allFinanceiro = {AppAction.view, AppAction.insert, AppAction.update, AppAction.delete, AppAction.baixar};
const _ro          = {AppAction.view};

// Telas do ESCRITORIO (fallback hardcoded)
const _escritorioScreens = {
  AppScreen.logins:             _all,
  AppScreen.comunicados:        _all,
  AppScreen.regimeTributario:   _all,
  AppScreen.empresas:           _all,
  AppScreen.parceiros:          _all,
  AppScreen.setores:            _all,
  AppScreen.rolesPermissoes:    _all,
  AppScreen.produto:            _all,
  AppScreen.unidadeMedida:      _all,
  AppScreen.catalogoProduto:    _all,
  AppScreen.nfeSerie:           _all,
  AppScreen.contasPagar:        _allFinanceiro,
  AppScreen.contasReceber:      _allFinanceiro,
  AppScreen.trading:            _ro,
  AppScreen.chamados:           _all,
  AppScreen.formasPagamento:    _all,
  AppScreen.diretorios:         _all,
  AppScreen.arquivos:           _all,
  AppScreen.calendario:         _all,
  AppScreen.obrigacoesFiscais:  _all,
  AppScreen.pedidos:            _all,
  AppScreen.configuracoesAdmin: _all,
  AppScreen.contasBancarias:    _all,
  AppScreen.contaBancaria:      _all,
  AppScreen.dashboard:          _ro,
  AppScreen.feriados:           _all,
  AppScreen.funcionarios:       _all,
  AppScreen.kanbanChamados:     _all,
  AppScreen.nfeEntrada:         _all,
  AppScreen.nfeSaida:           _all,
  AppScreen.nfse:               _all,
  AppScreen.nfseServico:        _all,
  AppScreen.pdvNfce:            _all,
  AppScreen.configFiscal:       _all,
  AppScreen.dashKpis:                  _ro,
  AppScreen.dashFinanceCards:          _ro,
  AppScreen.dashFluxoDiario:           _ro,
  AppScreen.dashTendenciaFinanceira:   _ro,
  AppScreen.dashDistribuicaoClientes:  _ro,
  AppScreen.dashComparativoTrimestral: _ro,
  AppScreen.dashAlertas:               _ro,
  AppScreen.dashChamadosCards:         _ro,
  AppScreen.dashChamadosPie:           _ro,
  AppScreen.dashTendenciaChamados:     _ro,
  AppScreen.dashChatsLinha:            _ro,
  AppScreen.dashChatsDiario:           _ro,
  AppScreen.dashSaldoContas:           _ro,
  AppScreen.dashEvolucaoSaldos:        _ro,
  AppScreen.dashAtendimentoArea:       _ro,
  AppScreen.dashFinanceiroArea:        _ro,
  AppScreen.dashComercialArea:         _ro,
  AppScreen.dashDpArea:                _ro,
  AppScreen.dashFiscalArea:            _ro,
  AppScreen.dashMensalidadeArea:       _ro,
  AppScreen.ponto:                     _all,
  AppScreen.pontoWeb:                  _all,
  AppScreen.solicitacaoAjustePonto:    _all,
  AppScreen.ajustePonto:               _all,
  AppScreen.ged:        _all,
  AppScreen.chat:       _all,
  AppScreen.chatKanban: _all,
  AppScreen.perfil:     _all,
  AppScreen.boletoImportacaoLote: _allFinanceiro,
  AppScreen.alvaras:    _all,
  AppScreen.nfceGrid:   _all,
  AppScreen.cnabRemessa: _all,
  AppScreen.regraFiscal: _all,
  AppScreen.cobrancaAutomatica: _allFinanceiro,
  AppScreen.aprovacaoPagamentos: _allFinanceiro,
  AppScreen.sistemaTest: _all,
  AppScreen.rateioFinanceiro: _allFinanceiro,
  AppScreen.baixaAutomatica: _allFinanceiro,
  AppScreen.renegociacao: _allFinanceiro,
  AppScreen.contaContabil: _allFinanceiro,
  AppScreen.relatorioDpRh: _ro,
};

// ─────────────────────────────────────────────────────────────────────────────
// 6. Matriz fallback (hardcoded — usada quando backend não retorna permissões)
// ─────────────────────────────────────────────────────────────────────────────
final Map<UserProfile, Map<AppScreen, Set<AppAction>>> _fallbackMatrix = {
  UserProfile.system: { for (final s in AppScreen.values) s: _all },
  UserProfile.escritorio: _escritorioScreens,
  UserProfile.gerente: { ..._escritorioScreens, AppScreen.regimeTributario: const {} },
  UserProfile.financeiro: {
    AppScreen.parceiros:       _all,
    AppScreen.formasPagamento: _all,
    AppScreen.trading:         _ro,
    AppScreen.diretorios:      _all,
    AppScreen.arquivos:        _all,
    AppScreen.contasBancarias: _all,
    AppScreen.contaBancaria:   _all,
    AppScreen.contasPagar:     _allFinanceiro,
    AppScreen.contasReceber:   _allFinanceiro,
    AppScreen.nfeEntrada:      _all,
    AppScreen.nfeSaida:        _all,
    AppScreen.nfse:            _all,
    AppScreen.nfseServico:     _all,
    AppScreen.pdvNfce:         _all,
    AppScreen.configFiscal:    _all,
    AppScreen.dashboard:       _ro,
    AppScreen.dashKpis:                  _ro,
    AppScreen.dashFinanceCards:          _ro,
    AppScreen.dashFluxoDiario:           _ro,
    AppScreen.dashTendenciaFinanceira:   _ro,
    AppScreen.dashDistribuicaoClientes:  _ro,
    AppScreen.dashComparativoTrimestral: _ro,
    AppScreen.dashAlertas:               _ro,
    AppScreen.dashSaldoContas:           _ro,
    AppScreen.dashEvolucaoSaldos:        _ro,
    AppScreen.noticias:  _ro,
    AppScreen.perfil:    _all,
    AppScreen.calendario: _ro,
    AppScreen.ponto:     {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb:  {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
  },
  UserProfile.faturista: {
    AppScreen.empresas:        _ro,
    AppScreen.parceiros:       _all,
    AppScreen.produto:         _all,
    AppScreen.unidadeMedida:   _all,
    AppScreen.catalogoProduto: _all,
    AppScreen.nfeSerie:        _all,
    AppScreen.formasPagamento: _all,
    AppScreen.diretorios:      _all,
    AppScreen.arquivos:        _all,
    AppScreen.contasBancarias: _all,
    AppScreen.contaBancaria:   _all,
    AppScreen.contasPagar:     _allFinanceiro,
    AppScreen.contasReceber:   _allFinanceiro,
    AppScreen.nfeEntrada:      _all,
    AppScreen.nfeSaida:        _all,
    AppScreen.nfse:            _all,
    AppScreen.nfseServico:     _all,
    AppScreen.pdvNfce:         _all,
    AppScreen.configFiscal:    _all,
    AppScreen.noticias:        _ro,
    AppScreen.perfil:          _all,
    AppScreen.calendario:      _ro,
    AppScreen.ponto:           {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb:        {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
    AppScreen.chat:            _ro,
    AppScreen.comunicados:     _ro,
    AppScreen.chamados:        _all,
    AppScreen.ged:             _all,
  },
  UserProfile.ponto: {
    AppScreen.calendario:             _ro,
    AppScreen.ponto:                  {AppAction.view, AppAction.insert},
    AppScreen.pontoWeb:               {AppAction.view, AppAction.insert},
    AppScreen.solicitacaoAjustePonto: {AppAction.view, AppAction.insert},
    AppScreen.chat:                   _ro,
    AppScreen.comunicados:            _ro,
    AppScreen.noticias:               _ro,
    AppScreen.perfil:                 _ro,
  },
  UserProfile.semAcesso: {},
};

// ─────────────────────────────────────────────────────────────────────────────
// 7. Classe principal
// ─────────────────────────────────────────────────────────────────────────────
class SecurityMatrix {
  final UserProfile profile;
  final LoginEnum? tipoLogin;
  final String? aplicativoNome;

  /// Permissões vindas do banco (quando disponíveis)
  final Map<String, Set<AppAction>> _backendPerms;

  /// Cache de permissões por módulo+ação para avoid recalcular
  final Map<String, bool> _moduloAcaoCache;

  const SecurityMatrix._({
    required this.profile,
    this.tipoLogin,
    this.aplicativoNome,
    Map<String, Set<AppAction>> backendPerms = const {},
    Map<String, bool> moduloAcaoCache = const {},
  }) : _backendPerms = backendPerms, _moduloAcaoCache = moduloAcaoCache;

  factory SecurityMatrix.of(LoginModel? userInfo) {
    if (userInfo == null) return const SecurityMatrix._(profile: UserProfile.semAcesso);

    final login = userInfo.login;
    final tipoLogin = login?.tipoLogin;
    final aplicativoNome = login?.aplicativo?.nome;

    // MASTER sempre tem acesso total
    if (tipoLogin == LoginEnum.MASTER) {
      return SecurityMatrix._(
        profile: UserProfile.system,
        tipoLogin: tipoLogin,
        aplicativoNome: aplicativoNome,
        backendPerms: {},
      );
    }

    // Resolve perfil para fallback
    final roles = login?.roles ?? [];
    UserProfile resolved = UserProfile.semAcesso;
    const priority = [
      UserProfile.system, UserProfile.escritorio, UserProfile.gerente,
      UserProfile.financeiro, UserProfile.faturista, UserProfile.ponto,
    ];
    for (final p in priority) {
      final key = _roleKeyToProfile.entries
          .firstWhere((e) => e.value == p, orElse: () => const MapEntry('', UserProfile.semAcesso))
          .key;
      if (roles.any((r) => r.key == key)) { resolved = p; break; }
    }
    if (resolved == UserProfile.semAcesso && roles.isNotEmpty) resolved = UserProfile.escritorio;
    if (resolved == UserProfile.semAcesso && tipoLogin != null) resolved = UserProfile.escritorio;

    // Constrói mapa de permissões do backend (consolidado por tela — OR entre roles)
    // Indexado tanto pelo nome original quanto em minúsculas para matching case-insensitive
    final backendPerms = <String, Set<AppAction>>{};
    final rawPerms = (userInfo.permissoes != null && userInfo.permissoes!.isNotEmpty)
        ? userInfo.permissoes
        : PermissionService().currentPermissoes;
    if (rawPerms != null && rawPerms.isNotEmpty) {
      for (final p in rawPerms) {
        final actions = <AppAction>{};
        if (p.podeVer)      actions.add(AppAction.view);
        if (p.podeInserir)  actions.add(AppAction.insert);
        if (p.podeEditar)   actions.add(AppAction.update);
        if (p.podeDeletar)  actions.add(AppAction.delete);
        if (p.podeBaixar)   actions.add(AppAction.baixar);

        final origExisting = backendPerms[p.telaNome] ?? <AppAction>{};
        origExisting.addAll(actions);
        backendPerms[p.telaNome] = origExisting;

        final lowerKey = p.telaNome.toLowerCase();
        final lowerExisting = backendPerms[lowerKey] ?? <AppAction>{};
        lowerExisting.addAll(actions);
        backendPerms[lowerKey] = lowerExisting;
      }
    }

    return SecurityMatrix._(
      profile: resolved,
      tipoLogin: tipoLogin,
      aplicativoNome: aplicativoNome,
      backendPerms: backendPerms,
    );
  }

  factory SecurityMatrix.current() => SecurityMatrix.of(AuthUtility.userInfo);

  /// Mapeamento de aliases entre AppScreen e nomes de telas usados pelo backend
  static const Map<AppScreen, List<String>> _screenAliases = {
    AppScreen.calendario: ['calendario', 'calendarioguias'],
    AppScreen.chat: ['chat'],
    AppScreen.chatKanban: ['chatkanban', 'kanbanchat'],
    AppScreen.comunicados: ['comunicado', 'comunicados', 'alertas'],
    AppScreen.chamados: ['chamados', 'chamado'],
    AppScreen.kanbanChamados: ['kanbanchamados', 'kanban'],
    AppScreen.ged: ['arquivos', 'ged', 'diretorios', 'arquivo'],
    AppScreen.arquivos: ['arquivos', 'ged', 'diretorios', 'arquivo'],
    AppScreen.diretorios: ['diretorios', 'arquivos', 'ged'],
    AppScreen.contasPagar: ['contaspagar', 'contas_pagar'],
    AppScreen.contasReceber: ['contasreceber', 'contas_receber'],
    AppScreen.parceiros: ['parceiros', 'parceiro'],
    AppScreen.dashboard: ['dashboard'],
    AppScreen.contasBancarias: ['contabancaria', 'contasbancarias', 'conta_bancaria'],
    AppScreen.contaBancaria: ['contabancaria', 'contasbancarias', 'conta_bancaria'],
    AppScreen.ponto: ['ponto', 'pontoweb'],
    AppScreen.pontoWeb: ['pontoweb', 'ponto'],
    AppScreen.solicitacaoAjustePonto: ['solicitacaoajusteponto', 'solicitarajuste'],
    AppScreen.ajustePonto: ['ajusteponto'],
    AppScreen.funcionarios: ['funcionarios', 'funcionario'],
    AppScreen.feriados: ['feriados', 'feriado'],
    AppScreen.alvaras: ['alvaras', 'alvara'],
    AppScreen.mensalidades: ['mensalidades', 'mensalidade'],
    AppScreen.logins: ['logins', 'login'],
    AppScreen.roles: ['roles', 'permissoes'],
    AppScreen.rolesPermissoes: ['rolespermissoes', 'permissoes', 'roles'],
    AppScreen.formasPagamento: ['formaspagamento', 'formas_pagamento'],
    AppScreen.setores: ['setores', 'setor'],
    AppScreen.empresas: ['empresas', 'empresa', 'cadastroempresa'],
    AppScreen.regimeTributario: ['regimetributario', 'regime'],
    AppScreen.obrigacoesFiscais: ['obrigacoesfiscais', 'obrigacoes_fiscais'],
    AppScreen.pedidos: ['pedidos', 'pedidosvenda', 'pedidoscompra'],
    AppScreen.configuracoesAdmin: ['configuracoesadmin', 'configadmin'],
    AppScreen.configSistema: ['configsistema'],
    AppScreen.nfeEntrada: ['nfeentrada', 'nfe_entrada', 'nfeimportxml', 'nfeimportcsv'],
    AppScreen.nfeSaida: ['nfesaida', 'nfe_saida'],
    AppScreen.nfeSerie: ['nfeserie', 'nfe_serie'],
    AppScreen.pdvNfce: ['pdvnfce', 'pdv_nfce'],
    AppScreen.configFiscal: ['configfiscal', 'config_fiscal'],
    AppScreen.nfse: ['nfse'],
    AppScreen.nfseLista: ['nfse', 'nfselista'],
    AppScreen.nfseSerie: ['nfseserie', 'nfse_serie'],
    AppScreen.nfseServico: ['nfseservico', 'nfse_servico'],
    AppScreen.produto: ['produtos', 'produto'],
    AppScreen.unidadeMedida: ['unidademedida', 'unidade_medida'],
    AppScreen.catalogoProduto: ['catalogoproduto', 'catalagoproduto'],
    AppScreen.importarExtrato: ['importarextrato', 'importar_extrato'],
    AppScreen.conciliacaoBancaria: ['conciliacaobancaria', 'conciliacao_bancaria'],
    AppScreen.lancamentosFinanceiros: ['lancamentosfinanceiros', 'lancamentos_financeiros'],
    AppScreen.integracoesFinanceiras: ['integracoesfinanceiras', 'integracoes_financeiras'],
    AppScreen.cobranca: ['cobranca', 'cobrancaautomatica'],
    AppScreen.dreGerencial: ['dre', 'dregerencial'],
    AppScreen.tipoParceiro: ['tipoparceiro', 'tipo_parceiro'],
    AppScreen.servicoContratado: ['servicocontratado', 'servicoscontratados'],
    AppScreen.moduloServico: ['moduloservico', 'modulosservicos'],
    AppScreen.trading: ['trading', 'tradingpainel'],
    AppScreen.noticias: ['noticias'],
    AppScreen.perfil: ['perfil'],
    AppScreen.boletoImportacaoLote: ['importarboletoslote', 'boletoimportacaolote'],
    AppScreen.dashFinanceiroArea: ['dashboardfinanceiro', 'dashfinanceiroarea'],
    AppScreen.dashComercialArea: ['dashboardcomercial', 'dashcomercialarea'],
    AppScreen.dashFiscalArea: ['dashboardfiscal', 'dashfiscalarea'],
    AppScreen.dashDpArea: ['dashboarddp', 'dashdparea'],
    AppScreen.dashAtendimentoArea: ['dashboardatendimento', 'dashatendimentoarea'],
    AppScreen.dashMensalidadeArea: ['dashboardmensalidades', 'dashmensalidadearea'],
    AppScreen.nfceGrid: ['nfce_grid', 'nfcegrid', 'nfce_cupom', 'nfce cupons'],
    AppScreen.cnabRemessa: ['cnab_remessa', 'cnabremessa', 'cnab', 'remessaedi'],
    AppScreen.regraFiscal: ['regra_fiscal', 'regrafiscal'],
    AppScreen.cobrancaAutomatica: ['cobranca_automatica', 'cobrancaautomatica'],
    AppScreen.aprovacaoPagamentos: ['aprovacao_pagamentos_web', 'aprovacao_pagamentos', 'aprovacaopagamentos', 'aprovacaopagamento'],
    AppScreen.sistemaTest: ['sistema_test', 'sistematest', 'systemtest', 'teste_endpoints'],
    AppScreen.rateioFinanceiro: ['rateio_financeiro', 'rateiofinanceiro'],
    AppScreen.baixaAutomatica: ['baixa_automatica', 'baixaautomatica'],
    AppScreen.renegociacao: ['renegociacao'],
    AppScreen.contaContabil: ['conta_contabil', 'contacontabil', 'planocontas'],
    AppScreen.relatorioDpRh: ['relatorio_dp_rh', 'relatoriodprh'],
  };

  /// Procura permissões de uma tela considerando nome direto, lowercase e aliases
  Set<AppAction>? _findPerms(AppScreen screen) {
    if (_backendPerms.isEmpty) return null;
    if (_backendPerms.containsKey(screen.name)) {
      return _backendPerms[screen.name];
    }
    final lower = screen.name.toLowerCase();
    if (_backendPerms.containsKey(lower)) {
      return _backendPerms[lower];
    }
    final aliases = _screenAliases[screen];
    if (aliases != null) {
      for (final alias in aliases) {
        if (_backendPerms.containsKey(alias)) {
          return _backendPerms[alias];
        }
        final lowerAlias = alias.toLowerCase();
        if (_backendPerms.containsKey(lowerAlias)) {
          return _backendPerms[lowerAlias];
        }
      }
    }
    return null;
  }

  bool _can(AppScreen screen, AppAction action) {
    // MASTER/SYSTEM: acesso total
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return ModuloAccess.isScreenAllowed(screen);
    }

    // Regra Financeiro Limitado: cliente sem módulo Financeiro completo só pode
    // VER e BAIXAR em Contas a Pagar; Contas a Receber fica bloqueada.
    if (screen == AppScreen.contasPagar &&
        !ModuloAccess.isModuloContratado('Financeiro') &&
        ModuloAccess.isModuloContratado('Financeiro Limitado')) {
      return action == AppAction.view || action == AppAction.baixar;
    }

    // Se backend retornou permissões, usa elas (fonte de verdade RBAC).
    // ModuloAccess só filtra quando módulos estão efetivamente configurados;
    // se a API retornou lista vazia, a permissão RBAC prevalece.
    if (_backendPerms.isNotEmpty) {
      final perms = _findPerms(screen);
      if (perms == null) return false;
      if (!perms.contains(action)) return false;
      return !ModuloAccess.hasModulosConfigurados || ModuloAccess.isScreenAllowed(screen);
    }

    // Fallback: matrix hardcoded
    final hasRole = _fallbackMatrix[profile]?[screen]?.contains(action) ?? false;
    if (!hasRole) return false;
    return !ModuloAccess.hasModulosConfigurados || ModuloAccess.isScreenAllowed(screen);
  }

  bool canView(AppScreen screen)   => _can(screen, AppAction.view);
  bool canInsert(AppScreen screen) => _can(screen, AppAction.insert);
  bool canUpdate(AppScreen screen) => _can(screen, AppAction.update);
  bool canDelete(AppScreen screen) => _can(screen, AppAction.delete);
  bool canBaixar(AppScreen screen) => _can(screen, AppAction.baixar);

  // ───────────────────────────────────────────────────────────────────────────
  // Enforcement por telaNome canônico (= MenuConfig.id). Independe do enum
  // AppScreen (que cobre só parte das telas). Usado pelo filtro do menu lateral.
  // ───────────────────────────────────────────────────────────────────────────

  /// MASTER/SYSTEM têm acesso total e ignoram o filtro de permissões.
  bool get isMaster =>
      profile == UserProfile.system || tipoLogin == LoginEnum.MASTER;

  /// IDs de tela (telaNome) que o usuário pode VISUALIZAR, vindas do backend.
  /// Só filtra por módulo quando módulos estão efetivamente configurados.
  Set<String> get viewableTelaIds {
    final result = <String>{};
    _backendPerms.forEach((tela, actions) {
      if (!actions.contains(AppAction.view)) return;
      if (ModuloAccess.hasModulosConfigurados) {
        final screen = AppScreen.values.where((s) => s.name.toLowerCase() == tela.toLowerCase()).firstOrNull;
        if (screen != null && !ModuloAccess.isScreenAllowed(screen)) return;
      }
      result.add(tela);
    });
    return result;
  }

  /// Calcula quais [allKnownIds] (ids do menu) o usuário pode ver.
  /// Retorna `null` apenas para MASTER/SYSTEM (mostrar tudo).
  /// Para demais usuarios, retorna o conjunto de ids liberados (pode ser vazio).
  /// Deny-by-default: sem permissoes = sem acesso ao menu.
  Set<String>? allowedTelaIds(Set<String> allKnownIds) {
    if (isMaster) return null;
    // Se nao ha permissoes do backend, usa fallback da matrix hardcoded
    if (_backendPerms.isEmpty) {
      // Usa a matrix fallback para determinar telas visiveis
      final fallbackViewable = <String>{};
      for (final id in allKnownIds) {
        final screen = AppScreen.values.where((s) => s.name.toLowerCase() == id.toLowerCase()).firstOrNull;
        if (screen != null && canView(screen)) {
          fallbackViewable.add(id);
        }
      }
      return fallbackViewable;
    }
    final viewableLower = viewableTelaIds.map((t) => t.toLowerCase()).toSet();
    final allowed = <String>{};
    for (final id in allKnownIds) {
      if (viewableLower.contains(id.toLowerCase())) {
        allowed.add(id);
      }
    }
    return allowed;
  }

  bool hasRoleKey(String roleKey) {
    final roles = AuthUtility.userInfo?.login?.roles ?? const [];
    return roles.any((role) => role.key == roleKey);
  }

  bool get canManageFiscalEvents {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) return true;
    return hasRoleKey('ROLE_ADMIN') || hasRoleKey('ROLE_FISCAL');
  }

  bool get isFinanceiroLimitado =>
      !ModuloAccess.isModuloContratado('Financeiro') &&
      ModuloAccess.isModuloContratado('Financeiro Limitado');

  bool hasAnyAccess(AppScreen screen) {
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) return true;
    if (_backendPerms.isNotEmpty) return (_findPerms(screen)?.isNotEmpty) ?? false;
    return (_fallbackMatrix[profile]?[screen]?.isNotEmpty) ?? false;
  }

  /// Verifica se o usuário tem uma ação específica em um módulo.
  /// Retorna false se o módulo não existe ou se não há a ação.
  /// Usa cache para evitar recálculos repetidos.
  bool canActionInModulo(AppAction acao, String nomeModulo) {
    // MASTER/SYSTEM: acesso total
    if (profile == UserProfile.system || tipoLogin == LoginEnum.MASTER) {
      return true;
    }

    // Valida se o módulo existe
    if (!_moduloToScreens.containsKey(nomeModulo)) {
      return false;
    }

    // Chave de cache: "nomeModulo:acao"
    final cacheKey = '$nomeModulo:${acao.name}';
    if (_moduloAcaoCache.containsKey(cacheKey)) {
      return _moduloAcaoCache[cacheKey] ?? false;
    }

    // Calcula: há permissão para a ação em ALGUMA tela do módulo?
    final telasDModulo = _moduloToScreens[nomeModulo] ?? {};
    bool temAcao = false;

    for (final tela in telasDModulo) {
      if (_can(tela, acao)) {
        temAcao = true;
        break;
      }
    }

    // Retorna e "cacheia" (em cache imutável, só pra leitura)
    // Nota: em Dart, Map const não permite update; em produção,
    // usar mutable Map se cache crescer demais (pode-se usar LRU).
    return temAcao;
  }

  List<AppScreen> get visibleScreens => AppScreen.values.where((s) => canView(s)).toList();

  List<AppScreen> get visibleSidebarScreens => [
    AppScreen.logins, AppScreen.comunicados, AppScreen.regimeTributario,
    AppScreen.empresas, AppScreen.parceiros, AppScreen.setores,
    AppScreen.contasPagar, AppScreen.contasReceber, AppScreen.chamados,
    AppScreen.formasPagamento, AppScreen.diretorios, AppScreen.arquivos,
    AppScreen.calendario, AppScreen.obrigacoesFiscais, AppScreen.pedidos,
    AppScreen.configuracoesAdmin, AppScreen.contasBancarias, AppScreen.contaBancaria,
    AppScreen.dashboard, AppScreen.feriados, AppScreen.funcionarios,
    AppScreen.kanbanChamados, AppScreen.chatKanban, AppScreen.nfeEntrada, AppScreen.nfeSaida, AppScreen.pdvNfce, AppScreen.configFiscal,
    AppScreen.pontoWeb, AppScreen.solicitacaoAjustePonto, AppScreen.ajustePonto,
    AppScreen.noticias, AppScreen.perfil, AppScreen.roles,
    AppScreen.produto, AppScreen.unidadeMedida, AppScreen.catalogoProduto, AppScreen.nfeSerie,
    AppScreen.tipoParceiro, AppScreen.servicoContratado, AppScreen.moduloServico,
    AppScreen.trading,
  ].where((s) => canView(s)).toList();

  List<AppScreen> get visibleDashboardWidgets => [
    AppScreen.dashKpis, AppScreen.dashFinanceCards, AppScreen.dashFluxoDiario,
    AppScreen.dashTendenciaFinanceira, AppScreen.dashDistribuicaoClientes,
    AppScreen.dashComparativoTrimestral, AppScreen.dashAlertas,
    AppScreen.dashChamadosCards, AppScreen.dashChamadosPie,
    AppScreen.dashTendenciaChamados, AppScreen.dashChatsLinha,
    AppScreen.dashChatsDiario, AppScreen.dashSaldoContas, AppScreen.dashEvolucaoSaldos,
  ].where((s) => canView(s)).toList();

  @override
  String toString() => 'SecurityMatrix(profile: $profile, tipo: $tipoLogin, app: $aplicativoNome, backendPerms: ${_backendPerms.length} telas)';
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. Controle de Acesso por Modulo Contratado
// ─────────────────────────────────────────────────────────────────────────────
const Map<String, Set<AppScreen>> _moduloToScreens = {
  'Financeiro': {
    AppScreen.contasPagar, AppScreen.contasReceber, AppScreen.contasBancarias,
    AppScreen.contaBancaria, AppScreen.formasPagamento, AppScreen.trading,
    AppScreen.dashFinanceCards, AppScreen.dashFluxoDiario,
    AppScreen.dashTendenciaFinanceira, AppScreen.dashComparativoTrimestral,
    AppScreen.dashSaldoContas, AppScreen.dashEvolucaoSaldos,
    // Fase 171 — dashboard de área Financeiro reaproveita o mesmo módulo já
    // usado pelo dashboard financeiro legado (Tarefa F3a do PLAN.md).
    AppScreen.dashFinanceiroArea,
    // Dashboard de mensalidades do escritorio (contaReceber MENS-/MOD-)
    AppScreen.dashMensalidadeArea,
    // CNAB / Remessa EDI — integração bancária
    AppScreen.cnabRemessa,
    AppScreen.cobrancaAutomatica, AppScreen.aprovacaoPagamentos,
    AppScreen.rateioFinanceiro, AppScreen.baixaAutomatica,
    AppScreen.renegociacao, AppScreen.mensalidades,
  },
  'Notas Fiscais': {
    AppScreen.nfeEntrada, AppScreen.nfeSaida, AppScreen.pdvNfce, AppScreen.nfceGrid,
    AppScreen.configFiscal, AppScreen.obrigacoesFiscais,
    AppScreen.produto, AppScreen.unidadeMedida, AppScreen.catalogoProduto, AppScreen.nfeSerie,
    AppScreen.dashFiscalArea, AppScreen.regraFiscal,
  },
  'Departamento Pessoal': {
    AppScreen.ponto, AppScreen.pontoWeb, AppScreen.solicitacaoAjustePonto,
    AppScreen.ajustePonto, AppScreen.funcionarios, AppScreen.feriados,
    AppScreen.dashDpArea, AppScreen.relatorioDpRh,
  },
  'Chamados': {
    AppScreen.chamados, AppScreen.kanbanChamados,
    AppScreen.dashChamadosCards, AppScreen.dashChamadosPie, AppScreen.dashTendenciaChamados,
    AppScreen.dashAtendimentoArea,
  },
  'Financeiro Limitado': {
    AppScreen.contasPagar,
  },
  'Comunicados': { AppScreen.comunicados },
  'Chat': { AppScreen.chat, AppScreen.chatKanban, AppScreen.dashChatsLinha, AppScreen.dashChatsDiario },
  'GED': { AppScreen.ged, AppScreen.diretorios, AppScreen.arquivos },
  'Dashboard': { AppScreen.dashboard, AppScreen.dashKpis, AppScreen.dashAlertas, AppScreen.dashDistribuicaoClientes },
  // Modulo NFS-e separado de 'Notas Fiscais' (produto). Keystone [P0][ARQUITETURA].
  'NFS-e': {
    AppScreen.nfse,
    AppScreen.obrigacoesFiscais,
  },
  'Contábil': {
    AppScreen.contaContabil, AppScreen.lancamentoContabil, AppScreen.balancete,
    AppScreen.fechamentoPeriodo, AppScreen.aiDashboard, AppScreen.aiAssistente,
  },
  // Card #219 — módulo Comercial: telas mínimas para o cliente criar nota de venda.
  // pdvNfce duplicado intencionalmente com 'Notas Fiscais' (OR logic em isScreenAllowed).
  'Comercial': {
    AppScreen.parceiros,
    AppScreen.produto,
    AppScreen.unidadeMedida,
    AppScreen.catalogoProduto,
    AppScreen.pedidos,
    AppScreen.pdvNfce,
    AppScreen.formasPagamento,
    AppScreen.dashComercialArea,
  },
};

class ModuloAccess {
  static List<String> _modulosContratados = [];
  static List<String> get modulosContratados => _modulosContratados;
  static bool _loaded = false;

  static Future<void> load() async {
    final login = AuthUtility.userInfo?.login;
    final parceiroId = login?.parceiro?.id;
    final empresaId = login?.empresa?.id;
    final tipoLogin = login?.tipoLogin;

    if (tipoLogin == LoginEnum.MASTER) {
      _modulosContratados = _moduloToScreens.keys.toList();
      _loaded = true;
      return;
    }
    final token = AuthUtility.userInfo?.token;
    final headers = {
      if (token != null) 'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    Set<String> empresaModulos = {};
    Set<String> parceiroModulos = {};

    if (empresaId != null) {
      try {
        final url = '${ApiLinks.baseUrl}/api/empresa-modulo?empresaId=$empresaId';
        final resp = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final List<dynamic> data = jsonDecode(resp.body);
          empresaModulos = data.map((m) => m['nome']?.toString() ?? '').toSet();
        } else {
          developer.log('API ${resp.statusCode} ao buscar empresa-módulos');
          throw Exception('API ${resp.statusCode} empresa-módulos');
        }
      } on TimeoutException {
        developer.log('Timeout ao buscar empresa-módulos');
        rethrow;
      } on Exception {
        developer.log('Erro ao buscar empresa-módulos');
        rethrow;
      }
    }

    if (parceiroId != null) {
      try {
        final url = '${ApiLinks.baseUrl}/api/parceiro-modulo?parceiroId=$parceiroId';
        final resp = await http.get(Uri.parse(url), headers: headers)
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          final List<dynamic> data = jsonDecode(resp.body);
          parceiroModulos = data.map((m) => m['nome']?.toString() ?? '').toSet();
        } else {
          developer.log('API ${resp.statusCode} ao buscar parceiro-módulos');
          throw Exception('API ${resp.statusCode} parceiro-módulos');
        }
      } on TimeoutException {
        developer.log('Timeout ao buscar parceiro-módulos');
        rethrow;
      } on Exception {
        developer.log('Erro ao buscar parceiro-módulos');
        rethrow;
      }
    }

    if (empresaModulos.isNotEmpty && parceiroModulos.isNotEmpty) {
      _modulosContratados = empresaModulos.intersection(parceiroModulos).toList();
    } else if (empresaModulos.isNotEmpty) {
      _modulosContratados = empresaModulos.toList();
    } else if (parceiroModulos.isNotEmpty) {
      _modulosContratados = parceiroModulos.toList();
    } else {
      // Deny-by-default: sem modulos contratados = sem acesso a telas de modulo.
      // Antes era permissivo (_moduloToScreens.keys.toList() = acesso total).
      // MASTER ja e tratado acima e nunca chega aqui.
      _modulosContratados = [];
    }
    if (_modulosContratados.isNotEmpty && !_modulosContratados.contains('Financeiro')) {
      _modulosContratados.add('Financeiro Limitado');
    }
    _loaded = true;
  }

  static const Map<String, List<String>> _moduloAliases = {
    'Notas Fiscais': [
      'Notas Fiscais',
      'Fiscal / NFC-e',
      'Fiscal e NF-e',
      'NFC-e',
      'Fiscal',
    ],
    'Financeiro': [
      'Financeiro',
      'Financeiro Limitado',
      'Financeiro avançado',
      'Financeiro avancado',
    ],
    'Departamento Pessoal': [
      'Departamento Pessoal',
      'RH',
      'Recursos Humanos',
      'DP',
    ],
    'Contábil': [
      'Contábil',
      'Contabil',
    ],
    'Bolsa de Valores': [
      'Bolsa de Valores',
      'Trading',
      'Investimentos',
    ],
    'NFS-e': [
      'NFS-e',
      'NFSe',
    ],
    'Comercial': [
      'Comercial',
    ],
    'Chamados': [
      'Chamados',
    ],
    'Chat': [
      'Chat',
    ],
    'Comunicados': [
      'Comunicados',
    ],
    'GED': [
      'GED',
    ],
  };

  static bool isScreenAllowed(AppScreen screen) {
    if (!_loaded) return true;

    // Verifica se a tela pertence a algum modulo
    bool pertenceAAlgumModulo = false;
    for (final entry in _moduloToScreens.entries) {
      if (entry.value.contains(screen)) {
        pertenceAAlgumModulo = true;
        final aliases = _moduloAliases[entry.key] ?? [entry.key];
        if (aliases.any(_modulosContratados.contains)) return true;
      }
    }
    // Tela que nao pertence a nenhum modulo e livre (ex: perfil, logins)
    if (!pertenceAAlgumModulo) return true;
    // Tela pertence a modulo mas nenhum modulo contratado a cobre: NEGAR
    return false;
  }

  /// Indica se os módulos já foram carregados da API ou do teste
  static bool get isLoaded => _loaded;

  /// Indica se algum módulo foi efetivamente configurado na API.
  /// Quando false, o filtro de módulo não deve bloquear telas com permissão RBAC.
  static bool get hasModulosConfigurados => _loaded && _modulosContratados.isNotEmpty;

  static bool isModuloContratado(String nome) {
    if (!_loaded) return false;
    final aliases = _moduloAliases[nome] ?? [nome];
    return aliases.any(_modulosContratados.contains);
  }

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
    'aprovacao_pagamentos_web': 'Financeiro',
    'calendario_guias': 'Financeiro',
    'importar_boletos_lote': 'Financeiro',
    'integracoes_financeiras': 'Financeiro',
    'dashboard': 'Financeiro',
    'dashboard_financeiro': 'Financeiro',
    'mensalidades': 'Financeiro',
    'dashMensalidadeArea': 'Financeiro',
    'dashboard_mensalidades': 'Financeiro',

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
    'regra_fiscal': 'Notas Fiscais',

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
    'relatorio_dp_rh': 'Departamento Pessoal',

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

  static bool isMenuItemAllowed(String menuItemId) {
    if (!_loaded) return true;
    final modulo = _menuItemToModulo[menuItemId];
    if (modulo == null) return true;

    // Módulos legados opcionais: só são liberados se contratados especificamente
    if (modulo == 'GME') return isModuloContratado('GME');
    if (modulo == 'Service Desk') {
      return isModuloContratado('Service Desk') || isModuloContratado('Service');
    }
    if (modulo == 'Projetos') return isModuloContratado('Projetos');
    if (modulo == 'Precificação') {
      return isModuloContratado('Precificação') || isModuloContratado('Precificacao');
    }

    if (!hasModulosConfigurados) return true;
    return isModuloContratado(modulo);
  }

  static List<AppScreen> filter(List<AppScreen> screens) =>
      screens.where((s) => isScreenAllowed(s)).toList();

  static void reset() { _modulosContratados = []; _loaded = false; }

  /// Define os módulos contratados diretamente, sem chamada de rede — só
  /// para testes unitários de SecurityMatrix/ModuloAccess (Tarefa F4, Fase
  /// 171). Nunca usar em código de produção.
  @visibleForTesting
  static void setContratadosParaTeste(List<String> modulos) {
    _modulosContratados = modulos;
    _loaded = true;
  }
}

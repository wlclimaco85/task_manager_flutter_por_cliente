import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

import '../../utils/security_matrix.dart';
import '../../web/screens/conta_pagar_grid_screen.dart' as web_screens;
import '../../windows/screens/conta_pagar_grid_screen.dart' as windows_screens;
import '../../mobile/screens/conta_pagar_grid_screen.dart' as mobile_screens;
import '../../web/screens/chamado_grid_screen.dart' as web_chamados;
import '../../windows/screens/chamado_grid_screen.dart' as windows_chamados;
import '../../mobile/screens/chamado_grid_screen_dynamic.dart' as mobile_chamados;
import '../../web/screens/kanban_chamados_screen.dart' as web_kanban;
import '../../windows/screens/kanban_chamados_screen.dart' as windows_kanban;
import '../../web/screens/chatMessageListScreen.dart' as web_chat;
import '../../windows/screens/chatMessageListScreen.dart' as windows_chat;
import '../../mobile/screens/chatMessageListScreen.dart' as mobile_chat;
import '../../web/screens/conta_receber_grid_screen.dart' as web_receber;
import '../../windows/screens/conta_receber_grid_screen.dart' as windows_receber;
import '../../mobile/screens/conta_receber_grid_screen.dart' as mobile_receber;
import '../../web/screens/orcamento_grid_screen.dart' as web_orcamento;
import '../../windows/screens/orcamento_grid_screen.dart' as windows_orcamento;
import '../../web/screens/pedido_venda_grid_screen.dart' as web_pedido;
import '../../windows/screens/pedido_venda_grid_screen.dart' as windows_pedido;
import '../../web/screens/devolucao_grid_screen.dart' as web_devolucao;
import '../../windows/screens/devolucao_grid_screen.dart' as windows_devolucao;
import '../../web/screens/funcionario_grid_screen.dart' as web_funcionario;
import '../../windows/screens/funcionario_grid_screen.dart' as windows_funcionario;
import '../../mobile/screens/funcionario_grid_screen.dart' as mobile_funcionario;
import '../../widgets/dp/dp_dynamic_grid_screen.dart';
import '../../web/screens/nfe_grid_screen.dart' as web_nfe;
import '../../windows/screens/nfe_grid_screen.dart' as windows_nfe;
import '../../web/screens/nfce/pdv_screen.dart' as web_pdv;
import '../../windows/screens/nfce/pdv_screen.dart' as windows_pdv;
import '../../web/screens/obrigacao_fiscal_grid_screen.dart' as web_obrigacao;
import '../../windows/screens/obrigacao_fiscal_grid_screen.dart' as windows_obrigacao;
import '../../windows/screens/nfse_screen.dart' as windows_nfse;

/// Resolve drillDownRota (String vindo do backend) para a tela operacional
/// Flutter real correspondente — Tarefa F1b (Onda 0, contrato de drill-down).
///
/// Se a rota não estiver registrada (string desconhecida ou null), nenhuma
/// ação é tomada — o KpiCard já garante (via onTap condicional) que só chama
/// navigate quando a rota é conhecida, mas o no-op aqui é uma segunda guarda
/// contra crash silencioso.
class DrillDownRouter {
  DrillDownRouter._();

  static final Map<String, WidgetBuilder> _rotas = {
    // Primeira entrada real — prova de conceito (Onda 0/F1b). Reaproveita a
    // tela operacional já existente de contas a pagar, resolvendo a Screen
    // correta por form factor (mesmo padrão condicional usado em main.dart).
    'contaPagarGrid': (context) {
      if (kIsWeb) {
        return web_screens.WebContaPagarGridScreen(hasPermission: (p) => true);
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_screens.WindowsContaPagarGridScreen(hasPermission: (p) => true);
      }
      return mobile_screens.ContaPagarGridScreen(hasPermission: (p) => true);
    },
    'chamadoGrid': (context) {
      final sec = SecurityMatrix.current();
      if (kIsWeb) {
        return web_chamados.WebChamadoGridScreen(
            hasPermission: (action) => _hasPermission(sec, AppScreen.chamados, action));
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_chamados.WindowsChamadoGridScreen(
            hasPermission: (action) => _hasPermission(sec, AppScreen.chamados, action));
      }
      return const mobile_chamados.ChamadosScreenDinamic();
    },
    'kanbanChamados': (context) {
      if (kIsWeb) {
        return const web_kanban.KanbanChamadosScreen();
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return const windows_kanban.KanbanChamadosScreen();
      }
      return const mobile_chamados.ChamadosScreenDinamic();
    },
    'chatList': (context) {
      if (kIsWeb) {
        return const web_chat.WebChatListScreen(userName: '');
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return const windows_chat.WindowsChatListScreen(userName: '');
      }
      return const mobile_chat.ChatListScreen(userName: '');
    },

    // ── Drill-down Financeiro ────────────────────────────────────────────────
    'contaReceberGrid': (context) {
      if (kIsWeb) {
        return web_receber.WebContaReceberGridScreen(hasPermission: (p) => true);
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_receber.WindowsContaReceberGridScreen(hasPermission: (p) => true);
      }
      return mobile_receber.ContaReceberGridScreen(hasPermission: (p) => true);
    },

    // ── Drill-down Comercial ─────────────────────────────────────────────────
    'orcamentoGrid': (context) {
      if (kIsWeb) {
        return const web_orcamento.WebOrcamentoGridScreen();
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return const windows_orcamento.WindowsOrcamentoGridScreen();
      }
      return const windows_orcamento.WindowsOrcamentoGridScreen();
    },
    'pedidoVendaGrid': (context) {
      if (kIsWeb) {
        return const web_pedido.WebPedidoVendaGridScreen();
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_pedido.WindowsPedidoVendaGridScreen(hasPermission: (p) => true);
      }
      return windows_pedido.WindowsPedidoVendaGridScreen(hasPermission: (p) => true);
    },
    'devolucaoComercialGrid': (context) {
      if (kIsWeb) {
        return const web_devolucao.WebDevolucaoGridScreen();
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return const windows_devolucao.WindowsDevolucaoGridScreen();
      }
      return const windows_devolucao.WindowsDevolucaoGridScreen();
    },

    // ── Drill-down Departamento Pessoal ───────────────────────────────────────
    'funcionarioGrid': (context) {
      if (kIsWeb) {
        return web_funcionario.WebFuncionarioGridScreen(hasPermission: (p) => true);
      }
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return windows_funcionario.WindowsFuncionarioGridScreen(hasPermission: (p) => true);
      }
      return mobile_funcionario.FuncionarioGridScreen(hasPermission: (p) => true);
    },
    'dpAdmissaoGrid': (context) =>
        const DpDynamicGridScreen(telaNome: 'dp_admissao'),
    'dpDesligamentoGrid': (context) =>
        const DpDynamicGridScreen(telaNome: 'dp_desligamento'),
    'dpFeriasGrid': (context) =>
        const DpDynamicGridScreen(telaNome: 'dp_ferias'),
    'folhaPontoGrid': (context) =>
        const DpDynamicGridScreen(telaNome: 'folha_ponto_fechamento'),

    // ── Drill-down Fiscal ───────────────────────────────────────────────────
    'nfeGrid': (context) {
      if (kIsWeb) {
        return const web_nfe.WebNfeGridScreen(entrada: false);
      }
      return const windows_nfe.WindowsNfeGridScreen(entrada: false);
    },
    'pdvNfce': (context) {
      if (kIsWeb) {
        return const web_pdv.PdvScreen();
      }
      return const windows_pdv.PdvScreen();
    },
    'nfseGrid': (context) => const windows_nfse.NfseScreen(),
    'obrigacaoFiscalGrid': (context) {
      final sec = SecurityMatrix.current();
      if (kIsWeb) {
        return web_obrigacao.WebObrigacaoFiscalGridScreen(
            hasPermission: (action) => _hasPermission(sec, AppScreen.obrigacoesFiscais, action));
      }
      return windows_obrigacao.WindowsObrigacaoFiscalGridScreen(
          hasPermission: (action) => _hasPermission(sec, AppScreen.obrigacoesFiscais, action));
    },
  };

  /// Resolve o builder para [drillDownRota], ou null se não houver entrada
  /// registrada.
  static WidgetBuilder? resolve(String? drillDownRota) {
    if (drillDownRota == null) return null;
    return _rotas[drillDownRota];
  }

  static bool _hasPermission(SecurityMatrix sec, AppScreen screen, String action) {
    final normalized = action.toLowerCase();
    if (normalized.contains('insert') || normalized.contains('create')) {
      return sec.canInsert(screen);
    }
    if (normalized.contains('edit') || normalized.contains('update')) {
      return sec.canUpdate(screen);
    }
    if (normalized.contains('delete') || normalized.contains('remove')) {
      return sec.canDelete(screen);
    }
    return sec.canView(screen);
  }

  /// Navega para a tela operacional resolvida a partir de [drillDownRota].
  /// periodoInicio/periodoFim são recebidos pelo contrato comum (Onda 0) mas
  /// não são repassados à tela de destino nesta prova de conceito — a tela de
  /// contas a pagar já filtra por TenantContext automaticamente; filtro de
  /// período explícito fica a cargo de cada card dependente quando aplicável.
  static void navigate(
    BuildContext context,
    String? drillDownRota,
    DateTime? periodoInicio,
    DateTime? periodoFim,
  ) {
    final builder = resolve(drillDownRota);
    if (builder == null) return; // no-op silencioso — rota desconhecida
    Navigator.push(context, MaterialPageRoute(builder: builder));
  }
}

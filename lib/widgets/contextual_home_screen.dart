import 'package:flutter/material.dart';
import '../utils/grid_colors.dart';
import '../utils/security_matrix.dart';
import '../utils/module_priority.dart';
import '../models/auth_utility.dart';

/// Tela "Início" contextual: resolve o módulo de maior prioridade do cliente
/// e exibe conteúdo relevante + atalhos para o módulo.
///
/// Regras (Card fpUG2UUE):
/// - Comercial       → destaque PDV/NFC-e
/// - NFS-e           → destaque NFS-e
/// - Financeiro      → Calendário Financeiro
/// - Financeiro limitado → Contas a Pagar
/// - Departamento Pessoal → Ponto
///
/// A navegação concreta é delegada via callback [onNavigate].
class ContextualHomeScreen extends StatelessWidget {
  final void Function(String rota) onNavigate;

  const ContextualHomeScreen({
    super.key,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final sec = SecurityMatrix.current();
    final contratados = ModuloAccess.modulosContratados;
    final modulo = ModulePriority.highest(contratados);
    final userName = AuthUtility.userInfo?.login?.nome ?? 'Usuário';
    final ehLimitado = modulo == 'Financeiro' && sec.isFinanceiroLimitado;

    String descricao;
    IconData icone;
    String rotaPrincipal;

    if (modulo == null) {
      descricao = 'Bem-vindo ao sistema';
      icone = Icons.home;
      rotaPrincipal = 'dashboard';
    } else {
      switch (modulo) {
        case 'Comercial':
          descricao = 'Emita notas fiscais de venda no PDV';
          icone = Icons.point_of_sale;
          rotaPrincipal = 'pdv';
          break;
        case 'NFS-e':
          descricao = 'Emita e consulte notas fiscais de serviço';
          icone = Icons.description;
          rotaPrincipal = 'nfse';
          break;
        case 'Financeiro':
          if (ehLimitado) {
            descricao = 'Consulte e baixe contas a pagar';
            icone = Icons.monetization_on;
            rotaPrincipal = 'contas_pagar';
          } else {
            descricao = 'Acompanhe o calendário de vencimentos';
            icone = Icons.calendar_month;
            rotaPrincipal = 'calendario';
          }
          break;
        case 'Departamento Pessoal':
          descricao = 'Registre e acompanhe pontos';
          icone = Icons.access_time;
          rotaPrincipal = 'ponto';
          break;
        default:
          descricao = 'Bem-vindo ao sistema';
          icone = Icons.home;
          rotaPrincipal = 'dashboard';
      }
    }

    return Scaffold(
      backgroundColor: GridColors.pageBackground,
      appBar: AppBar(
        backgroundColor: GridColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          modulo != null ? 'Módulo $modulo' : 'Início',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(
              userName: userName,
              descricao: descricao,
              icone: icone,
              rotaPrincipal: rotaPrincipal,
            ),
            const SizedBox(height: 24),
            if (modulo != null)
              _buildModuleShortcuts(modulo, sec)
            else
              _buildGenericShortcuts(sec),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard({
    required String userName,
    required String descricao,
    required IconData icone,
    required String rotaPrincipal,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: GridColors.divider),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: GridColors.secondarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icone, color: GridColors.secondary, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, $userName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: GridColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        descricao,
                        style: const TextStyle(
                          fontSize: 13,
                          color: GridColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onNavigate(rotaPrincipal),
                icon: Icon(icone, size: 18),
                label: Text('Abrir módulo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GridColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleShortcuts(String modulo, SecurityMatrix sec) {
    final items = <_ModuloShortcut>[];

    switch (modulo) {
      case 'Comercial':
        if (sec.canView(AppScreen.pdvNfce)) {
          items.add(_ModuloShortcut(Icons.point_of_sale, 'PDV / NFC-e', 'pdv'));
        }
        if (sec.canView(AppScreen.produto)) {
          items.add(_ModuloShortcut(Icons.inventory, 'Produtos', 'produtos'));
        }
        if (sec.canView(AppScreen.parceiros)) {
          items.add(_ModuloShortcut(Icons.handshake, 'Clientes', 'parceiros'));
        }
        if (sec.canView(AppScreen.pedidos)) {
          items.add(_ModuloShortcut(
              Icons.shopping_cart, 'Pedidos Venda', 'pedidos_venda'));
        }
        break;
      case 'NFS-e':
        if (sec.canView(AppScreen.nfseLista)) {
          items.add(
              _ModuloShortcut(Icons.description, 'Consultar NFS-e', 'nfse'));
        }
        break;
      case 'Financeiro':
        if (sec.isFinanceiroLimitado) {
          if (sec.canView(AppScreen.contasPagar)) {
            items.add(_ModuloShortcut(
                Icons.payments, 'Contas a Pagar', 'contas_pagar'));
          }
        } else {
          if (sec.canView(AppScreen.calendario)) {
            items.add(_ModuloShortcut(
                Icons.calendar_month, 'Calendário', 'calendario'));
          }
          if (sec.canView(AppScreen.contasPagar)) {
            items.add(_ModuloShortcut(
                Icons.payments, 'Contas a Pagar', 'contas_pagar'));
          }
          if (sec.canView(AppScreen.contasReceber)) {
            items.add(_ModuloShortcut(Icons.account_balance_wallet,
                'Contas a Receber', 'contas_receber'));
          }
        }
        break;
      case 'Departamento Pessoal':
        if (sec.canView(AppScreen.ponto)) {
          items.add(_ModuloShortcut(Icons.access_time, 'Bater Ponto', 'ponto'));
        }
        if (sec.canView(AppScreen.funcionarios)) {
          items.add(
              _ModuloShortcut(Icons.badge, 'Funcionários', 'funcionarios'));
        }
        break;
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Atalhos do módulo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GridColors.textSecondary,
            ),
          ),
        ),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _shortcutTile(item.icon, item.label, item.rota),
            )),
      ],
    );
  }

  Widget _buildGenericShortcuts(SecurityMatrix sec) {
    final items = <_ModuloShortcut>[];

    if (sec.canView(AppScreen.dashboard)) {
      items.add(_ModuloShortcut(Icons.bar_chart, 'Dashboard', 'dashboard'));
    }
    if (sec.canView(AppScreen.chat)) {
      items.add(_ModuloShortcut(Icons.chat, 'Chat', 'chat'));
    }
    if (sec.canView(AppScreen.comunicados)) {
      items.add(_ModuloShortcut(Icons.article, 'Comunicados', 'comunicados'));
    }
    if (sec.canView(AppScreen.chamados)) {
      items.add(
          _ModuloShortcut(Icons.confirmation_number, 'Chamados', 'chamados'));
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Funcionalidades',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GridColors.textSecondary,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.92,
          ),
          itemBuilder: (_, index) => _gridItemTile(items[index]),
        ),
      ],
    );
  }

  Widget _shortcutTile(IconData icon, String label, String rota) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onNavigate(rota),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GridColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: GridColors.secondarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: GridColors.secondary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: GridColors.textSecondary,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right,
                  color: GridColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gridItemTile(_ModuloShortcut item) {
    return InkWell(
      onTap: () => onNavigate(item.rota),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GridColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: GridColors.secondarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: GridColors.secondary, size: 18),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GridColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuloShortcut {
  final IconData icon;
  final String label;
  final String rota;
  const _ModuloShortcut(this.icon, this.label, this.rota);
}

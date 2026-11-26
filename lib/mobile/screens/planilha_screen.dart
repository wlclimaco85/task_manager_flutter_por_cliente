import 'package:flutter/material.dart';

import '../../services/menu_publicado_service.dart';
import '../../services/permission_service.dart';
import '../../utils/tenant_context.dart';
import '../../widgets/planilha_construtor_view.dart';
import '../../widgets/planilha_view.dart';
import '../../widgets/tela_publicada_view.dart';

class MobilePlanilhaScreen extends StatelessWidget {
  const MobilePlanilhaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Planilhas')),
      body: const SafeArea(child: PlanilhaView()),
    );
  }
}

class MobileConstrutorPlanilhasScreen extends StatelessWidget {
  const MobileConstrutorPlanilhasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Construtor de Planilhas')),
      body: const SafeArea(child: PlanilhaConstrutorView()),
    );
  }
}

/// Itens publicados no menu que o usuario pode ver (MASTER ve todos).
class MobileItensPublicadosScreen extends StatefulWidget {
  const MobileItensPublicadosScreen({super.key});

  @override
  State<MobileItensPublicadosScreen> createState() => _MobileItensPublicadosScreenState();
}

class _MobileItensPublicadosScreenState extends State<MobileItensPublicadosScreen> {
  late final Future<void> _carga = MenuPublicadoService().carregarNoMenu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Itens publicados')),
      body: FutureBuilder<void>(
        future: _carga,
        builder: (context, s) {
          if (s.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final itens = MenuPublicadoService.atuais
              .where((i) => TenantContext.isMaster || PermissionService().canViewScreen(i.menuId))
              .toList();
          if (itens.isEmpty) return const Center(child: Text('Nenhum item publicado para você.'));
          return ListView(children: [
            for (final item in itens)
              ListTile(
                minVerticalPadding: 14,
                title: Text(item.titulo),
                subtitle: Text(item.grupo),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => Scaffold(
                              appBar: AppBar(title: Text(item.titulo)),
                              body: SafeArea(child: TelaPublicadaView(item: item)),
                            ))),
              ),
          ]);
        },
      ),
    );
  }
}

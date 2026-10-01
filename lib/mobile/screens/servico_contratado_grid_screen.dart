import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Serviços Contratados — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileServicoContratadoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileServicoContratadoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_servico_contratado'),
      telaNome: 'servico_contratado',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_servico_contratado',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

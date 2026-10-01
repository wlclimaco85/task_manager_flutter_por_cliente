import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Módulos de Serviço — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileModuloServicoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileModuloServicoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_modulo_servico'),
      telaNome: 'modulo_servico',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_modulo_servico',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

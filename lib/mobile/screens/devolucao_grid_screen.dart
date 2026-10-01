import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Devoluções — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileDevolucaoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileDevolucaoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_devolucao'),
      telaNome: 'devolucao',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_devolucao',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

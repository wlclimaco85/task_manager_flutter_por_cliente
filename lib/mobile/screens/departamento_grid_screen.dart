import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Departamentos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileDepartamentoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileDepartamentoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_departamento'),
      telaNome: 'departamento',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_departamento',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

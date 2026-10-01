import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Empresas — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileEmpresaGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileEmpresaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_empresa'),
      telaNome: 'empresa',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_empresa',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

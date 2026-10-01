import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Aplicativo — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileAplicativoScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileAplicativoScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_aplicativo'),
      telaNome: 'aplicativo',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_aplicativo',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

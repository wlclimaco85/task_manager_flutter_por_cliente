import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Alimentos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileAlimentoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileAlimentoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_alimento'),
      telaNome: 'alimento',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_alimento',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

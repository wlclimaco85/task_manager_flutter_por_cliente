import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Cargos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileCargoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileCargoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_cargo'),
      telaNome: 'cargo',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_cargo',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

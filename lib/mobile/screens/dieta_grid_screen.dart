import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Dietas — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileDietaGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileDietaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_dieta'),
      telaNome: 'dieta',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_dieta',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

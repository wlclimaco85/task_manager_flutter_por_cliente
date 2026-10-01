import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Suplementos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileSuplementoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileSuplementoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_suplemento'),
      telaNome: 'suplemento',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_suplemento',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

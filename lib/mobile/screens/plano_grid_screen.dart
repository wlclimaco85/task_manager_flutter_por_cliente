import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Planos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobilePlanoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobilePlanoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_plano'),
      telaNome: 'plano',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_plano',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

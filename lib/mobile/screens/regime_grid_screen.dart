import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Regime Tributário — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileRegimeGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileRegimeGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_regime'),
      telaNome: 'regime',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_regime',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

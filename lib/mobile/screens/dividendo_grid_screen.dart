import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Dividendos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileDividendoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileDividendoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_dividendo'),
      telaNome: 'dividendo',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_dividendo',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

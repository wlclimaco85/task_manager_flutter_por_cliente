import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Centros de Custo — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileCentroCustoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileCentroCustoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_centro_custo'),
      telaNome: 'centro_custo',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_centro_custo',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

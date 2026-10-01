import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Unidades de Medida — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileUnidadeMedidaGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileUnidadeMedidaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_unidade_medida'),
      telaNome: 'unidade_medida',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_unidade_medida',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

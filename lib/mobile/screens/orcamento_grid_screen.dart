import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Orçamentos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileOrcamentoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileOrcamentoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_orcamento'),
      telaNome: 'orcamento',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_orcamento',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Plano de Contas — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileContaContabilGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileContaContabilGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_conta_contabil'),
      telaNome: 'conta_contabil',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_conta_contabil',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

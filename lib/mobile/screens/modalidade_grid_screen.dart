import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Modalidades — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileModalidadeGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileModalidadeGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_modalidade'),
      telaNome: 'modalidade',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_modalidade',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

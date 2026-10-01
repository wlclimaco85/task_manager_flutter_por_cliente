import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Setores — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileSetorGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileSetorGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_setor'),
      telaNome: 'setor',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_setor',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

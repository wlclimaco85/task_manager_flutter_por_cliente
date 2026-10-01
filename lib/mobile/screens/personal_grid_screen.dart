import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Personais — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobilePersonalGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobilePersonalGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_personal'),
      telaNome: 'personal',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_personal',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

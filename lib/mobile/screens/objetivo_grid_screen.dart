import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Objetivos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileObjetivoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileObjetivoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_objetivo'),
      telaNome: 'objetivo',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_objetivo',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

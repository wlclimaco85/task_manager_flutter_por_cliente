import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Treinos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileTreinoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileTreinoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_treino'),
      telaNome: 'treino',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_treino',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

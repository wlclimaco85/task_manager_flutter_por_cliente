import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Exercícios — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileExercicioGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileExercicioGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_exercicio'),
      telaNome: 'exercicio',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_exercicio',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

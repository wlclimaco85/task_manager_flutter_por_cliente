import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Avaliação Física — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileAvaliacaoFisicaGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileAvaliacaoFisicaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_avaliacao_fisica'),
      telaNome: 'avaliacao_fisica',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_avaliacao_fisica',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

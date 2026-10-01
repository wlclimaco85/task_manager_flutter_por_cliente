import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Classificação — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileClassificacaoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileClassificacaoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_classificacao'),
      telaNome: 'classificacao',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_classificacao',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

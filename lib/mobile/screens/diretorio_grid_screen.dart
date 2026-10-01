import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Diretórios — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileDiretorioGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileDiretorioGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_diretorio'),
      telaNome: 'diretorio',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_diretorio',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

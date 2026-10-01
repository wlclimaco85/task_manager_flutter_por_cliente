import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Feriados — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileFeriadoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileFeriadoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_feriado'),
      telaNome: 'feriado',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_feriado',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

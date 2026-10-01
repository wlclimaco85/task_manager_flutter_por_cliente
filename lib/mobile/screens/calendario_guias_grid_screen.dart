import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Calendário de Guias — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileCalendarioGuiasGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileCalendarioGuiasGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_calendario_guias'),
      telaNome: 'calendario_guias',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_calendario_guias',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

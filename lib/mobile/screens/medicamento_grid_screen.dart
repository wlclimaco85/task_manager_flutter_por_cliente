import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Medicamentos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileMedicamentoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileMedicamentoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_medicamento'),
      telaNome: 'medicamento',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_medicamento',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

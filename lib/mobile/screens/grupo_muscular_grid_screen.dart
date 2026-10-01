import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Grupos Musculares — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileGrupoMuscularGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileGrupoMuscularGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_grupo_muscular'),
      telaNome: 'grupo_muscular',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_grupo_muscular',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

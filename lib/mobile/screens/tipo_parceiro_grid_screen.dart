import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Tipos de Parceiro — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileTipoParceiroGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileTipoParceiroGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_tipo_parceiro'),
      telaNome: 'tipo_parceiro',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_tipo_parceiro',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

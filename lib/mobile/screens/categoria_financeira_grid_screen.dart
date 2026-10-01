import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Categorias Financeiras — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileCategoriaFinanceiraGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileCategoriaFinanceiraGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_categoria_financeira'),
      telaNome: 'categoria_financeira',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_categoria_financeira',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

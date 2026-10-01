import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Catálogo de Produtos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileCatalagoProdutoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileCatalagoProdutoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_catalogo_produto'),
      telaNome: 'catalogo_produto',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_catalogo_produto',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebTipoProdutoGridScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileWebTipoProdutoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'tipo_produto',
      hasPermission: hasPermission ?? ((_) => true),
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

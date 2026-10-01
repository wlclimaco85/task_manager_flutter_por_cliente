import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Aprovação de Compras — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileAprovacaoCompraScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileAprovacaoCompraScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_aprovacao_compra'),
      telaNome: 'aprovacao_compra',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_aprovacao_compra',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Pedidos — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobilePedidoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobilePedidoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_pedido'),
      telaNome: 'pedido',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_pedido',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

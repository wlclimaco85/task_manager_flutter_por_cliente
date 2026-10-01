import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Pedidos de Compra — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobilePedidoCompraGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobilePedidoCompraGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_pedido_compra'),
      telaNome: 'pedido_compra',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_pedido_compra',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

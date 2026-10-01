import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Pedidos de Venda — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobilePedidoVendaGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobilePedidoVendaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_pedido_venda'),
      telaNome: 'pedido_venda',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_pedido_venda',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

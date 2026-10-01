import 'package:flutter/material.dart';
import '../../../../web/screens/details/pedido_compra_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobilePedidoCompraDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? item;
  final bool Function(String)? hasPermission;

  const MobilePedidoCompraDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Pedido de Compra',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.PedidoCompraDetailScreen(item: item!)
            : DynamicGridDynamicScreen(
                telaNome: 'pedido_compra',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

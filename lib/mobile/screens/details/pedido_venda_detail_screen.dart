import 'package:flutter/material.dart';
import '../../../../web/screens/details/pedido_venda_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobilePedidoVendaDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? item;
  final bool Function(String)? hasPermission;

  const MobilePedidoVendaDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Pedido de Venda',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.PedidoVendaDetailScreen(item: item!)
            : DynamicGridDynamicScreen(
                telaNome: 'pedido_venda',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

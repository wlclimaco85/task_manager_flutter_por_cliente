import 'package:flutter/material.dart';
import '../../../../web/screens/details/produto_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebProdutoDetailScreen extends StatelessWidget {
  final dynamic item;
  final bool Function(String)? hasPermission;

  const MobileWebProdutoDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Produto',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null && item is Map<String, dynamic>
            ? web.WebProdutoDetailScreen(
                item: item as Map<String, dynamic>,
                hasPermission: hasPermission ?? ((_) => true),
              )
            : DynamicGridDynamicScreen(
                telaNome: 'produto',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

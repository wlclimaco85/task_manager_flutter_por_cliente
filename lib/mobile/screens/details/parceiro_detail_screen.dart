import 'package:flutter/material.dart';
import '../../../../web/screens/details/parceiro_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebParceiroDetailScreen extends StatelessWidget {
  final dynamic item;
  final bool Function(String)? hasPermission;
  final String? titleOverride;

  const MobileWebParceiroDetailScreen({
    super.key,
    this.item,
    this.hasPermission,
    this.titleOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: titleOverride ?? 'Parceiro',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null && item is Map<String, dynamic>
            ? web.WebParceiroDetailScreen(
                item: item as Map<String, dynamic>,
                hasPermission: hasPermission ?? ((_) => true),
                titleOverride: titleOverride,
              )
            : DynamicGridDynamicScreen(
                telaNome: 'parceiro',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

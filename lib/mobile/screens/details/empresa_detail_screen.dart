import 'package:flutter/material.dart';
import '../../../../web/screens/details/empresa_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebEmpresaDetailScreen extends StatelessWidget {
  final dynamic item;
  final bool Function(String)? hasPermission;

  const MobileWebEmpresaDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Empresa',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null && item is Map<String, dynamic>
            ? web.WebEmpresaDetailScreen(
                item: item as Map<String, dynamic>,
                hasPermission: hasPermission ?? ((_) => true),
              )
            : DynamicGridDynamicScreen(
                telaNome: 'empresa',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

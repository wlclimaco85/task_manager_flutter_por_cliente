import 'package:flutter/material.dart';
import '../../../../web/screens/details/funcionario_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebFuncionarioDetailScreen extends StatelessWidget {
  final dynamic item;
  final bool Function(String)? hasPermission;

  const MobileWebFuncionarioDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Funcionário',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null && item is Map<String, dynamic>
            ? web.WebFuncionarioDetailScreen(
                item: item as Map<String, dynamic>,
                hasPermission: hasPermission ?? ((_) => true),
              )
            : DynamicGridDynamicScreen(
                telaNome: 'funcionario',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

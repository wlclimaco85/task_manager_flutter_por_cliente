import 'package:flutter/material.dart';
import '../../../../web/screens/details/chamado_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';
import '../../../../models/chamado_model.dart';

class MobileWebChamadoDetailScreen extends StatelessWidget {
  final dynamic item;
  final bool Function(String)? hasPermission;

  const MobileWebChamadoDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Chamado',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.WebChamadoDetailScreen(
                item: item is Chamado
                    ? item as Chamado
                    : Chamado.fromJson(item as Map<String, dynamic>),
                hasPermission: hasPermission ?? ((_) => true),
              )
            : DynamicGridDynamicScreen(
                telaNome: 'chamado',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

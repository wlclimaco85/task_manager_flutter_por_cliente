import 'package:flutter/material.dart';
import '../../../../web/screens/details/regime_tributario_detail.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';
import '../../../../models/regime_tributario_model.dart';

class MobileWebRegimeDetailScreen extends StatelessWidget {
  final dynamic item;
  final bool Function(String)? hasPermission;

  const MobileWebRegimeDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Regime Tributário',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.WebRegimeDetailScreen(
                item: item is RegimeTributario
                    ? item as RegimeTributario
                    : RegimeTributario.fromJson(item as Map<String, dynamic>),
                hasPermission: hasPermission ?? ((_) => true),
              )
            : DynamicGridDynamicScreen(
                telaNome: 'regime',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

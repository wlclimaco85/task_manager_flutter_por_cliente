import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class MobileRegraFiscalScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileRegraFiscalScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'regra_fiscal',
      hasPermission: hasPermission ?? ((_) => true),
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

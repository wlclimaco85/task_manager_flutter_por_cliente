import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebDashboardScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileWebDashboardScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'dashboard',
      hasPermission: hasPermission ?? ((_) => true),
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

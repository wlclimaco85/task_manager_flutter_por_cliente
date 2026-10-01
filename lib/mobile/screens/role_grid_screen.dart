import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Roles — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileRoleGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileRoleGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_role'),
      telaNome: 'role',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_role',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

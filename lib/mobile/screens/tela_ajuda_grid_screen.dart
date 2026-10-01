import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebTelaAjudaGridScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileWebTelaAjudaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'tela_ajuda',
      hasPermission: hasPermission ?? ((_) => true),
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebMensalidadeGridScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileWebMensalidadeGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'mensalidade',
      hasPermission: hasPermission ?? ((_) => true),
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

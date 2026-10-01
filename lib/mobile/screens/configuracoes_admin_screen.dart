import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Configurações Admin — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileConfiguracoesAdminScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileConfiguracoesAdminScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_config_admin'),
      telaNome: 'config_admin',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_config_admin',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

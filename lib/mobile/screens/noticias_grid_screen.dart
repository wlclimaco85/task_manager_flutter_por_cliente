import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Notícias — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileNoticiasGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileNoticiasGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_noticias'),
      telaNome: 'noticias',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_noticias',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

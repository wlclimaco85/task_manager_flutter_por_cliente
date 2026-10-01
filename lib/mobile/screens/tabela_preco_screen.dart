import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Tabela de Preços — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileTabelaPrecoScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileTabelaPrecoScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_tabela_preco'),
      telaNome: 'tabela_preco',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_tabela_preco',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

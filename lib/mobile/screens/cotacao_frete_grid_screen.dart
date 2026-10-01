import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Cotação de Frete — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileCotacaoFreteGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileCotacaoFreteGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_cotacao_frete'),
      telaNome: 'cotacao_frete',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_cotacao_frete',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

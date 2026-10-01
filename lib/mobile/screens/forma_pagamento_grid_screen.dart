import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Formas de Pagamento — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileFormaPagamentoGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileFormaPagamentoGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_forma_pagamento'),
      telaNome: 'forma_pagamento',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_forma_pagamento',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

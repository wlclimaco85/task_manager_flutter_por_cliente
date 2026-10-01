import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Lançamentos Financeiros — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileLancamentoFinanceiroGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileLancamentoFinanceiroGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_lancamento_financeiro'),
      telaNome: 'lancamento_financeiro',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_lancamento_financeiro',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

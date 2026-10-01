import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Obrigações Fiscais — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileObrigacaoFiscalGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileObrigacaoFiscalGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_obrigacao_fiscal'),
      telaNome: 'obrigacao_fiscal',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_obrigacao_fiscal',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

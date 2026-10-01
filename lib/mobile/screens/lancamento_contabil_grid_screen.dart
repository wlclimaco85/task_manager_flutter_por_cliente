import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Lançamentos Contábeis — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileLancamentoContabilGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileLancamentoContabilGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_lancamento_contabil'),
      telaNome: 'lancamento_contabil',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_lancamento_contabil',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

class MobileWebNotaFiscalEntradaGridScreen extends StatelessWidget {
  final bool Function(String)? hasPermission;

  const MobileWebNotaFiscalEntradaGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      telaNome: 'nota_fiscal_entrada',
      hasPermission: hasPermission ?? ((_) => true),
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

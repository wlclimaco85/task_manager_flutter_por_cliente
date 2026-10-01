import 'package:flutter/material.dart';
import '../../../../web/screens/details/modulo_cobranca_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobileModuloCobrancaScreen extends StatelessWidget {
  final Map<String, dynamic>? item;
  final bool Function(String)? hasPermission;

  const MobileModuloCobrancaScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Módulo de Cobrança',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.ModuloCobrancaScreen(
                parceiroId: item?['parceiroId'] ?? item?['id'] ?? 0,
                parceiroNome: item?['nome'] ?? 'Parceiro',
              )
            : DynamicGridDynamicScreen(
                telaNome: 'modulo_cobranca',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

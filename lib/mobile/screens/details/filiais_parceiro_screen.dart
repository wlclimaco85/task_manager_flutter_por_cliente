import 'package:flutter/material.dart';
import '../../../../web/screens/details/filiais_parceiro_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileFiliaisParceiroScreen extends StatelessWidget {
  final int matrizId;
  final int? empresaId;
  final bool Function(String)? hasPermission;

  const MobileFiliaisParceiroScreen({
    super.key,
    this.matrizId = 0,
    this.empresaId,
    this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Filiais do Parceiro',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.FiliaisParceiroScreen(
          matrizId: matrizId,
          empresaId: empresaId,
          hasPermission: hasPermission ?? ((_) => true),
        ),
      ),
    );
  }
}

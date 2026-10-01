import 'package:flutter/material.dart';
import '../../web/screens/role_permissao_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileRolePermissaoScreen extends StatelessWidget {

  const MobileRolePermissaoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Controle de Acesso',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.RolePermissaoScreen(),
      ),
    );
  }
}

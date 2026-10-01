import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/config_fiscal_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileConfigFiscalScreen extends StatelessWidget {
  const MobileConfigFiscalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'Configuração Fiscal NFC-e',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.ConfigFiscalScreen(),
      ),
    );
  }
}

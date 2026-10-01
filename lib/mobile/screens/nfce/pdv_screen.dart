import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/pdv_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobilePdvScreen extends StatelessWidget {
  const MobilePdvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: UserBannerAppBar(
        screenTitle: 'PDV NFC-e',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.PdvScreen(),
      ),
    );
  }
}

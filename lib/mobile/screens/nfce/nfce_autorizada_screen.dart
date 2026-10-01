import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/nfce_autorizada_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileNfceAutorizadaScreen extends StatelessWidget {
  final dynamic args;

  const MobileNfceAutorizadaScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'NFC-e Autorizada',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: const SafeArea(
        child: Center(
          child: Text('NFC-e Autorizada Mobile'),
        ),
      ),
    );
  }
}

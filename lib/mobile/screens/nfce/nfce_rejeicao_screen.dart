import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/nfce_rejeicao_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileNfceRejeicaoScreen extends StatelessWidget {
  final dynamic args;

  const MobileNfceRejeicaoScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Rejeição NFC-e',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Rejeição NFC-e Mobile'),
        ),
      ),
    );
  }
}

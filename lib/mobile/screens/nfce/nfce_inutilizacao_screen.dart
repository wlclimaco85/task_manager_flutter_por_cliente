import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/nfce_inutilizacao_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileNfceInutilizacaoScreen extends StatelessWidget {
  final dynamic args;

  const MobileNfceInutilizacaoScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Inutilização NFC-e',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Inutilização NFC-e Mobile'),
        ),
      ),
    );
  }
}

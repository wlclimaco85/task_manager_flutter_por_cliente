import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/nfce_cancelamento_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileNfceCancelamentoScreen extends StatelessWidget {
  final dynamic args;

  const MobileNfceCancelamentoScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Cancelamento NFC-e',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Cancelamento NFC-e Mobile'),
        ),
      ),
    );
  }
}

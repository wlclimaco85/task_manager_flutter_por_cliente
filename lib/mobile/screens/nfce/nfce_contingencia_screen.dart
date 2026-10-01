import 'package:flutter/material.dart';
import '../../../../web/screens/nfce/nfce_contingencia_screen.dart' as web;
import '../../../../widgets/user_banners.dart';

class MobileNfceContingenciaScreen extends StatelessWidget {
  final dynamic args;

  const MobileNfceContingenciaScreen({super.key, this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Contingência NFC-e',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: const SafeArea(
        child: Center(
          child: Text('Contingência NFC-e Mobile'),
        ),
      ),
    );
  }
}

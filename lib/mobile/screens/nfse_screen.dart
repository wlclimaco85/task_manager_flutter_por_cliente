import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_windows_screen.dart';
import '../../web/screens/nfse_screen.dart';

class MobileNfseScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;

  const MobileNfseScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: NfseScreen(
          hasPermission: hasPermission,
          isMobile: true,
        ),
      ),
    );
  }
}

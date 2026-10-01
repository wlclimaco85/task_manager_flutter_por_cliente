import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_windows_screen.dart';
import '../../web/screens/nfce_grid_screen.dart';

class MobileNfceGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;

  const MobileNfceGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebNfceGridScreen(
          hasPermission: hasPermission,
          isMobile: true,
        ),
      ),
    );
  }
}

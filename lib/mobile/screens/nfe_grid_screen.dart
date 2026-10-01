import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_windows_screen.dart';
import '../../web/screens/nfe_grid_screen.dart';

class MobileNfeGridScreen extends StatelessWidget {
  final bool entrada;
  final SecurityCheck? hasPermission;

  const MobileNfeGridScreen({
    super.key,
    required this.entrada,
    this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WebNfeGridScreen(
          entrada: entrada,
          hasPermission: hasPermission,
          isMobile: true,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../web/screens/comunicado_circular_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileComunicadoCircularScreen extends StatelessWidget {

  const MobileComunicadoCircularScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Comunicados Circulares',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.ComunicadoCircularScreen(),
      ),
    );
  }
}

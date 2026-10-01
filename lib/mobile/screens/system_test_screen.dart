import 'package:flutter/material.dart';
import '../../web/screens/system_test_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileSystemTestScreen extends StatelessWidget {

  const MobileSystemTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Diagnóstico de Sistema',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.SystemTestScreen(),
      ),
    );
  }
}

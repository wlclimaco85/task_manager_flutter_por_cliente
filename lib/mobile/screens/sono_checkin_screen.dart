import 'package:flutter/material.dart';
import '../../web/screens/sono_checkin_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileSonoCheckinScreen extends StatelessWidget {
  final int? alunoId;

  const MobileSonoCheckinScreen({super.key, this.alunoId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Sono & Check-in',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.SonoCheckinScreen(alunoId: alunoId ?? 0),
      ),
    );
  }
}

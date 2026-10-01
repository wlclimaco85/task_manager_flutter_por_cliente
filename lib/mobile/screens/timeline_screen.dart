import 'package:flutter/material.dart';
import '../../web/screens/timeline_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileTimelineScreen extends StatelessWidget {

  const MobileTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Linha do Tempo',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.TimelineScreen(),
      ),
    );
  }
}

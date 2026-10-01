import 'package:flutter/material.dart';
import '../../web/screens/match_screen.dart' as web;
import '../../widgets/user_banners.dart';

class MobileMatchScreen extends StatelessWidget {

  const MobileMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Comunidade / Match',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: web.MatchScreen(),
      ),
    );
  }
}

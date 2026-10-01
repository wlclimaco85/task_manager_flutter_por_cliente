import 'package:flutter/material.dart';
import '../../../../web/screens/details/personal_detail_screen.dart' as web;
import '../../../../widgets/user_banners.dart';
import '../../../../customization/dynamic_grid_dynamic_screen.dart';

class MobilePersonalDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? item;
  final bool Function(String)? hasPermission;

  const MobilePersonalDetailScreen({super.key, this.item, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const UserBannerAppBar(
        screenTitle: 'Personal',
        showFilterButton: false,
        showBackButton: true,
      ),
      body: SafeArea(
        child: item != null
            ? web.PersonalDetailScreen(item: item!, hasPermission: hasPermission ?? ((_) => true))
            : DynamicGridDynamicScreen(
                telaNome: 'personal',
                hasPermission: hasPermission ?? ((_) => true),
                showAppBar: false,
              ),
      ),
    );
  }
}

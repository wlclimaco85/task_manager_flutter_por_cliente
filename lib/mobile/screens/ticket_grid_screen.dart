import 'package:flutter/material.dart';
import '../../customization/dynamic_grid_dynamic_screen.dart';

/// Tela mobile de Tickets — usa DynamicGridDynamicScreen (layout vertical nativo em cards).
class MobileTicketGridScreen extends StatelessWidget {
  final SecurityCheck? hasPermission;
  const MobileTicketGridScreen({super.key, this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridDynamicScreen(
      key: const ValueKey('mobile_grid_ticket'),
      telaNome: 'ticket',
      hasPermission: hasPermission ?? (p) => true,
      storageKey: 'mobile_dynamic_ticket',
      showAppBar: true,
      useUserBannerAppBar: true,
    );
  }
}

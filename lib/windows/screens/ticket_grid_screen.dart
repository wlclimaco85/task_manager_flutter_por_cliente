import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/ticket_model.dart';

class WindowsTicketGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsTicketGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<TicketItem>(
      telaNome: 'Tickets',
      hasPermission: hasPermission,
      fromJson: (json) => TicketItem.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

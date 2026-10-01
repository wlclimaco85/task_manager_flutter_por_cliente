import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/order_model.dart';

class WindowsOrderGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsOrderGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<OrderItem>(
      telaNome: 'Ordens',
      hasPermission: hasPermission,
      fromJson: (json) => OrderItem.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

import 'package:flutter/material.dart';

import '../../customization/dynamic_grid_windows_screen.dart';

class DpDynamicGridScreen extends StatelessWidget {
  final String telaNome;

  const DpDynamicGridScreen({super.key, required this.telaNome});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: telaNome,
      hasPermission: (_) => true,
      fromJson: (json) => json,
      toJson: (item) => item,
    );
  }
}

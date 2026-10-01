import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WebModuloServicoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebModuloServicoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'modulo_servico',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
    );
  }
}

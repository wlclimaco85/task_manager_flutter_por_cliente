import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsServicoContratadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsServicoContratadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'servico_contratado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
    );
  }
}

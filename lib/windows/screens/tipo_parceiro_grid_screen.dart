import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsTipoParceiroGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsTipoParceiroGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'tipo_parceiro',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
    );
  }
}

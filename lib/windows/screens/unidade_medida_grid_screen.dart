import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsUnidadeMedidaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsUnidadeMedidaGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'unidade_medida', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}

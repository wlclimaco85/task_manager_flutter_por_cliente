import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WebUnidadeMedidaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebUnidadeMedidaGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'unidade_medida', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}

import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WindowsNfeTipoOperacaoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsNfeTipoOperacaoGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'nfe_tipo_operacao', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}

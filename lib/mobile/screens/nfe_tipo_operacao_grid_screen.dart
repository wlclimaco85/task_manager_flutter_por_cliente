import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WebNfeTipoOperacaoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebNfeTipoOperacaoGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'nfe_tipo_operacao', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}

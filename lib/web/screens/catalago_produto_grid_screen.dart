import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WebCatalagoProdutoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebCatalagoProdutoGridScreen({super.key, required this.hasPermission});
  @override
  Widget build(BuildContext context) => DynamicGridWindowsScreen<Map<String, dynamic>>(
    telaNome: 'produto', hasPermission: hasPermission,
    fromJson: (j) => j, toJson: (a) => a);
}

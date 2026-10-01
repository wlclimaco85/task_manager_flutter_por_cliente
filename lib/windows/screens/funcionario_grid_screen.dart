import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../windows/screens/details/funcionario_detail_screen.dart';

class WindowsFuncionarioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsFuncionarioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'funcionario',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) => WindowsFuncionarioDetailScreen(
        item: item,
        hasPermission: hasPermission,
      ),
    );
  }
}

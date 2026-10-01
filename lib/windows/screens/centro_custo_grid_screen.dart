import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/centro_custo_model.dart';

class WindowsCentroCustoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsCentroCustoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<CentroCusto>(
      telaNome: 'CentrosCusto',
      hasPermission: hasPermission,
      fromJson: (json) => CentroCusto.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

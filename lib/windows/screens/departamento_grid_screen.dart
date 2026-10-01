import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/departamento_model.dart';

class WindowsDepartamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsDepartamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Departamento>(
      telaNome: 'Departamentos',
      hasPermission: hasPermission,
      fromJson: (json) => Departamento.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

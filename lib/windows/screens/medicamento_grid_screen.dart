import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/medicamento_model.dart';

class WindowsMedicamentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsMedicamentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Medicamento>(
      telaNome: 'Medicamentos',
      hasPermission: hasPermission,
      fromJson: (json) => Medicamento.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

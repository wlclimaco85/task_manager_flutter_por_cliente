import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/alerta_model.dart';

class WindowsAlertaAlunoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsAlertaAlunoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Alerta>(
      telaNome: 'AlertaAluno',
      hasPermission: hasPermission,
      fromJson: (json) => Alerta.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

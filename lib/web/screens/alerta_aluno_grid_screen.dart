import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/alerta_model.dart';

class WebAlertaAlunoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebAlertaAlunoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Alerta>(
      telaNome: 'alerta_aluno',
      hasPermission: hasPermission,
      fromJson: (json) => Alerta.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}



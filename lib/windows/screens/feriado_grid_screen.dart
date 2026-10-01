import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/feriado_model.dart';

class WindowsFeriadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsFeriadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Feriado>(
      telaNome: 'Feriado',
      hasPermission: hasPermission,
      fromJson: (json) => Feriado.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

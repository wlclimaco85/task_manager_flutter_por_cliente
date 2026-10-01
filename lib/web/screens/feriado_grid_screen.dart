import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/feriado_model.dart';

class WebFeriadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebFeriadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Feriado>(
      telaNome: 'feriado',
      hasPermission: hasPermission,
      fromJson: (json) => Feriado.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}


import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/alimento_model.dart';

class WindowsAlimentoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsAlimentoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Alimento>(
      telaNome: 'ALIMENTOS', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Alimento.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

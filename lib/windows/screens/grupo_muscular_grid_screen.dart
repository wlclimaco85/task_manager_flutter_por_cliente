import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/grupo_muscular_model.dart';

class WindowsGrupoMuscularGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsGrupoMuscularGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<GrupoMuscular>(
      telaNome: 'Grupos Musculares', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => GrupoMuscular.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

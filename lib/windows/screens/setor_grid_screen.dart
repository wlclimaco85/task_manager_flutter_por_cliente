import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/setor_model.dart';

class WindowsSetorGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsSetorGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Setor>(
      telaNome: 'Setor', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Setor.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

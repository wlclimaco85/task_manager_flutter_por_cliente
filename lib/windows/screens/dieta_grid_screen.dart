import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/dieta_model.dart';

class WindowsDietaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsDietaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Dieta>(
      telaNome: 'Dietas',
      hasPermission: hasPermission,
      fromJson: (json) => Dieta.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

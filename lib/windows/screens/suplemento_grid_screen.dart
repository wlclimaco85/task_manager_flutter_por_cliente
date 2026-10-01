import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/suplemento_model.dart';

class WindowsSuplementoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsSuplementoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Suplemento>(
      telaNome: 'Suplementos', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Suplemento.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

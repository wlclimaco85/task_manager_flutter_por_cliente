import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/objetivo_model.dart';

class WindowsObjetivoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsObjetivoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Objetivo>(
      telaNome: 'Objetivos',
      hasPermission: hasPermission,
      fromJson: (json) => Objetivo.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

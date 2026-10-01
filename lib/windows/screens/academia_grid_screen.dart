import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/academia_model.dart';

class WindowsAcademiaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsAcademiaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Academia>(
      telaNome: 'academia',
      hasPermission: hasPermission,
      fromJson: (json) => Academia.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

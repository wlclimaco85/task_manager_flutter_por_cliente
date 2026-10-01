import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/cargo_model.dart';

class WindowsCargoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsCargoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Cargo>(
      telaNome: 'Cargos',
      hasPermission: hasPermission,
      fromJson: (json) => Cargo.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

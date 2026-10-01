import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/dividendo_model.dart';

class WindowsDividendoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsDividendoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Dividendo>(
      telaNome: 'Dividendos',
      hasPermission: hasPermission,
      fromJson: (json) => Dividendo.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

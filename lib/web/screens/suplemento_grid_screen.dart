import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/suplemento_model.dart';

class WebSuplementoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebSuplementoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Suplemento>(
      telaNome: 'suplemento', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Suplemento.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}



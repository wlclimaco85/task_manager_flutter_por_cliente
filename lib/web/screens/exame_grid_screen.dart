import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/exame_model.dart';

class WebExameGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebExameGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Exame>(
      telaNome: 'exame', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Exame.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}



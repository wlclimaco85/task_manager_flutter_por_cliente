import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/plano_model.dart';

class WebPlanoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebPlanoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Plano>(
      telaNome: 'planos', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Plano.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}



import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/aplicativo_model.dart';

class WebAplicativoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebAplicativoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Aplicativo>(
      telaNome: 'Aplicativo', // o nome que está no banco
      hasPermission: hasPermission,
      fromJson: (json) => Aplicativo.fromJson(json),
      toJson: (a) => a.toJson(),
    );
  }
}

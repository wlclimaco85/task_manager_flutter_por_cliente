import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/tela_ajuda_model.dart';

class WindowsTelaAjudaGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WindowsTelaAjudaGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<TelaAjudaModel>(
      telaNome: 'tela_ajuda',
      hasPermission: hasPermission,
      fromJson: TelaAjudaModel.fromJson,
      toJson: (ajuda) => ajuda.toJson(),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../models/modalidade_model.dart';

class WindowsModalidadeGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WindowsModalidadeGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Modalidade>(
      telaNome: 'Modalidades',
      hasPermission: hasPermission,
      fromJson: (json) => Modalidade.fromJson(json),
      toJson: (item) => item.toJson(),
    );
  }
}

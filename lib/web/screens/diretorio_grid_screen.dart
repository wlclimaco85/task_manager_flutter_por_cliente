import 'package:flutter/material.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../models/diretorio_model.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';

class WebDiretorioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebDiretorioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Diretorio>(
      telaNome: 'diretorio',
      hasPermission: hasPermission,
      fromJson: (json) => Diretorio.fromJson(json),
      toJson: (a) => a.toJson(),
      fieldOverrides: [
        DropdownHelpers.empresaField(required: true),
      ],
    );
  }
}

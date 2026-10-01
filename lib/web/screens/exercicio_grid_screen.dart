import 'package:flutter/material.dart';

import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;
import './details/exercicio_detail_screen.dart';

class WebExercicioGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;

  const WebExercicioGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'exercicios',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      detailScreenBuilder: (item) => ExercicioDetailScreen(
        item: item,
        hasPermission: hasPermission,
      ),
      fieldOverrides: [
        DropdownHelpers.grupoMuscularField(),
        const FieldConfigWindows(
          label: 'Nível',
          fieldName: 'nivel',
          icon: Icons.bar_chart,
          fieldType: FieldType.number,
          isInForm: true,
          isFilterable: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          label: 'Link do Vídeo',
          fieldName: 'linkVideo',
          icon: Icons.video_library,
          fieldType: FieldType.url,
          isInForm: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          label: 'Foto (URL)',
          fieldName: 'foto',
          icon: Icons.image,
          fieldType: FieldType.url,
          isInForm: true,
          enabled: true,
        ),
        const FieldConfigWindows(
          label: 'Link do Documento',
          fieldName: 'linkDoc',
          icon: Icons.article,
          fieldType: FieldType.url,
          isInForm: true,
          enabled: true,
        ),
      ],
    );
  }
}

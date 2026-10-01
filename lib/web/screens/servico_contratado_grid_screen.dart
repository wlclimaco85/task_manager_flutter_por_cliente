import 'package:flutter/material.dart';
import '../../../customization/dynamic_grid_windows_screen.dart';
import '../../../utils/dropdown_helpers.dart';
import '../../../widgets/generic_grid_windows_screen.dart' show FieldConfigWindows, FieldType;

class WebServicoContratadoGridScreen extends StatelessWidget {
  final SecurityCheck hasPermission;
  const WebServicoContratadoGridScreen({super.key, required this.hasPermission});

  @override
  Widget build(BuildContext context) {
    return DynamicGridWindowsScreen<Map<String, dynamic>>(
      telaNome: 'servico_contratado',
      hasPermission: hasPermission,
      fromJson: (json) => json,
      toJson: (a) => a,
      fieldOverrides: [
        DropdownHelpers.empresaField(),
        FieldConfigWindows(
          label: 'Parceiro',
          fieldName: 'parceiro',
          displayFieldName: 'parceiro.nome',
          fieldType: FieldType.dropdown,
          dropdownValueField: 'id',
          dropdownDisplayField: 'nome',
          enabled: true,
          isInForm: true,
          // Cascade: filtra parceiros pela empresa selecionada no form
          dependsOnField: 'empresa',
          dropdownFutureBuilderWithParam: DropdownHelpers.parceirosPorEmpresa,
        ),
        const FieldConfigWindows(
          label: 'Valor',
          fieldName: 'valor',
          fieldType: FieldType.currency,
          icon: Icons.attach_money,
          enabled: true,
          isInForm: true,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../customization/generic_grid/grid_models.dart' as mobile;
import '../widgets/generic_grid_windows_screen.dart' as desktop;

class ParceiroFormRules {
  static const moduleServiceAliases = [
    'modulo_servicos',
    'moduloServicos',
    'modulosServico',
  ];

  static List<desktop.FieldConfigWindows> desktopModuleSuppression() =>
      moduleServiceAliases
          .map(
            (fieldName) => desktop.FieldConfigWindows(
              label: '',
              fieldName: fieldName,
              isInForm: false,
              isInGrid: false,
              isVisibleByDefault: false,
            ),
          )
          .toList();

  static List<mobile.FieldConfig> mobileModuleSuppression() =>
      moduleServiceAliases
          .map(
            (fieldName) => mobile.FieldConfig(
              label: '',
              fieldName: fieldName,
              isInForm: false,
              isVisibleByDefault: false,
              showInCard: false,
            ),
          )
          .toList();

  static desktop.FieldConfigWindows desktopSupplierType() =>
      const desktop.FieldConfigWindows(
        label: 'Tipo Parceiros',
        fieldName: 'tipo_parceiros',
        icon: Icons.people_outline,
        fieldType: desktop.FieldType.multiselect,
        dropdownOptions: [
          {'nome': 'Fornecedor'},
        ],
        dropdownValueField: 'nome',
        dropdownDisplayField: 'nome',
        defaultValue: 'Fornecedor',
        dropdownSelectedValue: 'Fornecedor',
        isRequired: true,
        enabled: false,
      );

  static mobile.FieldConfig mobileSupplierType() => const mobile.FieldConfig(
        label: 'Tipo Parceiros',
        fieldName: 'tipo_parceiros',
        icon: Icons.people_outline,
        fieldType: mobile.FieldType.multiselect,
        dropdownOptions: [
          {'nome': 'Fornecedor'},
        ],
        dropdownValueField: 'nome',
        dropdownDisplayField: 'nome',
        defaultValue: 'Fornecedor',
        dropdownSelectedValue: 'Fornecedor',
        isRequired: true,
        enabled: false,
      );

  static Map<String, dynamic> removeSupplierTypeFromPayload(
    Map<String, dynamic> formData,
  ) {
    final result = Map<String, dynamic>.from(formData);
    for (final fieldName in const [
      'tipo_parceiros',
      'tiposParceiro',
      'tipos_parceiro',
      'tipoCliente',
    ]) {
      result.remove(fieldName);
    }
    return result;
  }
}

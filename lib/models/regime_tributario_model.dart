import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../services/network_caller.dart';
import '../../../models/network_response.dart';

// IMPORTA FieldConfig DO GRID ANTIGO
import '../customization/generic_grid_card.dart' as card;

// IMPORTA FieldConfigWindows DO NOVO GRID
import '../../../widgets/generic_grid_windows_screen.dart' as win
    show FieldConfigWindows, FieldType;

// IMPORTA TAB CONFIG DO DETAIL
import '../../../widgets/tab_config.dart';

class RegimeTributario {
  int? id;
  String? codigo;
  String? descricao;
  Map<String, dynamic>? aplicativo;

  RegimeTributario({
    this.id,
    this.codigo,
    this.descricao,
    this.aplicativo,
  });

  // ---------------------------
  // FROM JSON
  // ---------------------------
  RegimeTributario.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    codigo = json['codigo'];
    descricao = json['descricao'];
    aplicativo = json['aplicativo'];
  }

  // ---------------------------
  // TO JSON
  // ---------------------------
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'descricao': descricao,
      'aplicativo': aplicativo,
    };
  }

  static List<RegimeTributario> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((e) => RegimeTributario.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ---------------------------
  // DROPDOWN DE APLICATIVOS
  // ---------------------------
  static Future<List<Map<String, dynamic>>> loadDropdownData() async {
    final NetworkResponse response =
        await NetworkCaller().getRequest(ApiLinks.allAplicativos);

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!["data"]["dados"] ?? [];

      return data
          .map((item) => {
                'value': item['id'].toString(),
                'label': item['nome'].toString(),
              })
          .toList();
    }

    return [];
  }

  // --------------------------------------------
  // CONFIG DOS CAMPOS — TIPO ORIGINAL (card.FieldConfig)
  // --------------------------------------------
  static List<card.FieldConfig> fieldConfigs = [
    const card.FieldConfig(
      label: "Código",
      fieldName: "codigo",
      icon: Icons.qr_code,
      isInForm: true,
      isRequired: true,
    ),
    const card.FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isRequired: true,
    ),
    card.FieldConfig(
      label: "Aplicativo",
      fieldName: "aplicativo",
      displayFieldName: "aplicativo.nome",
      icon: Icons.apps,
      isInForm: true,
      fieldType: card.FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadDropdownData(),
      dropdownValueField: "value",
      dropdownDisplayField: "label",
      isRequired: true,
    ),
  ];

  // --------------------------------------------
  // CONVERTE PARA FieldConfigWindows (NOVO SISTEMA)
  // --------------------------------------------
  static List<win.FieldConfigWindows> fieldConfigsWindows() {
    return fieldConfigs.map((card.FieldConfig f) {
      // Mapeia o enum antigo para o enum de FieldType do Windows
      final win.FieldType mappedType = win.FieldType.values[f.fieldType.index];

      return win.FieldConfigWindows(
        label: f.label ?? "",
        fieldName: f.fieldName ?? "",
        displayFieldName: f.displayFieldName,
        fieldType: mappedType,
        icon: f.icon,
        isInForm: f.isInForm ?? true,
        isRequired: f.isRequired ?? false,
        isFilterable: f.isFilterable ?? true,
        isVisibleByDefault: f.isVisibleByDefault ?? true,
        isFixed: f.isFixed ?? false,
        enabled: f.enabled ?? true,
        maxLines: f.maxLines ?? 1,
        dropdownFutureBuilder: f.dropdownFutureBuilder,
        dropdownOptions: f.dropdownOptions,
        dropdownValueField: f.dropdownValueField ?? "value",
        dropdownDisplayField: f.dropdownDisplayField ?? "label",
        dropdownSelectedValue: f.dropdownSelectedValue,
      );
    }).toList();
  }

  // --------------------------------------------
  // TABS PARA O DETAIL SCREEN
  // --------------------------------------------
  static List<TabConfig> tabConfigs = [
    TabConfig(
      title: "Dados Principais",
      icon: Icons.info,
      isGrid: false,
      formFields: RegimeTributario.fieldConfigsWindows(),
    ),
    TabConfig(
      title: "Histórico",
      icon: Icons.history,
      isGrid: true,
      gridTelaNome: "RegimeHistorico",
    ),
  ];
}

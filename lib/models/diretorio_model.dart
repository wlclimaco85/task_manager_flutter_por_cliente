import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

import '../customization/generic_grid_card.dart';
import 'empresa_model.dart';

class Diretorio {
  int? id;
  String nome;
  String descricao;
  Empresa? empresa;

  Diretorio({
    this.id,
    required this.nome,
    required this.descricao,
    this.empresa,
  });

  factory Diretorio.fromJson(Map<String, dynamic> json) {
    return Diretorio(
      id: json['id'],
      nome: json['nome']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      empresa:
          json['empresa'] != null ? Empresa.fromJson(json['empresa']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'descricao': descricao, 'empresa': empresa};
  }

  static Future<List<Map<String, dynamic>>> loadCategorias() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allEmpresas,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'], 'label': item['nome'].toString()},
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.folder,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Empresa",
      fieldName: "empresa",
      displayFieldName: "empresa.nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async {
        return await loadCategorias();
      },
      dropdownValueField: 'value', // Altere para 'value'
      dropdownDisplayField: 'label', // Altere para 'label'
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}

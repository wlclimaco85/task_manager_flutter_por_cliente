import 'package:flutter/material.dart';
import '../customization/generic_grid_card.dart';

class Setor {
  int? id;
  String? nome;
  String? responsavel;
  String? ramal;

  Setor({this.id, this.nome, this.responsavel, this.ramal});

  Setor.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    // backend usa 'descricao', mas aceita 'nome' também
    nome = json['descricao']?.toString() ?? json['nome']?.toString();
    responsavel = json['responsavel']?.toString();
    ramal = json['ramal']?.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': nome,
      if (responsavel != null) 'responsavel': responsavel,
      if (ramal != null) 'ramal': ramal,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.apartment,
      isInForm: true,
      isFilterable: true,
    ),
  ];
}

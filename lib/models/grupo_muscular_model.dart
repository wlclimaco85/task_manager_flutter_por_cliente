import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class GrupoMuscular {
  int? id;
  String? nome;
  String? descricao;

  GrupoMuscular({this.id, this.nome, this.descricao});

  GrupoMuscular.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'descricao': descricao};
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.fitness_center,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
    ),
  ];
}

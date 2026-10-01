import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Departamento {
  int? id;
  String? nome;
  String? numeroFolha;

  Departamento({this.id, this.nome, this.numeroFolha});
  Departamento.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    numeroFolha = json['numeroFolha'];
  }
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'numeroFolha': numeroFolha};

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.business, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Número Folha", fieldName: "numeroFolha", icon: Icons.numbers, isInForm: true),
  ];
}

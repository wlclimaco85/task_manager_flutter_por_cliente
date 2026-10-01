import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Suplemento {
  int? id;
  String? nome;
  String? descricao;
  String? fabricante;

  Suplemento({this.id, this.nome, this.descricao, this.fabricante});

  Suplemento.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
    fabricante = json['fabricante'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'fabricante': fabricante,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.local_drink,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Fabricante",
      fieldName: "fabricante",
      icon: Icons.factory,
      isInForm: true,
    ),
  ];
}

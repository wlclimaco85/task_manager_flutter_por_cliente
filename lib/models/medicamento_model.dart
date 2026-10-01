import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Medicamento {
  int? id;
  String? nome;
  String? descricao;
  String? dosagem;
  String? laboratorio;

  Medicamento({
    this.id,
    this.nome,
    this.descricao,
    this.dosagem,
    this.laboratorio,
  });

  Medicamento.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
    dosagem = json['dosagem'];
    laboratorio = json['laboratorio'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'dosagem': dosagem,
      'laboratorio': laboratorio,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.medication,
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
      label: "Dosagem",
      fieldName: "dosagem",
      icon: Icons.scale,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Laboratório",
      fieldName: "laboratorio",
      icon: Icons.local_hospital,
      isInForm: true,
    ),
  ];
}

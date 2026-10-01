import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class CalendarioGuias {
  int? id;
  String? nome;
  String? descricao;
  String? dtGuia;

  CalendarioGuias({this.id, this.nome, this.descricao, this.dtGuia});

  CalendarioGuias.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
    dtGuia = json['dtGuia'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'descricao': descricao,
        'dtGuia': dtGuia,
      };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.calendar_today, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Descrição", fieldName: "descricao", icon: Icons.description, isInForm: true),
    const FieldConfig(label: "Data Guia", fieldName: "dtGuia", icon: Icons.date_range, isInForm: true),
  ];
}

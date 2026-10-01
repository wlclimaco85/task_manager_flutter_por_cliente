import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Feriado {
  int? id;
  String? nome;
  String? data;
  bool? repeteAno;

  Feriado({this.id, this.nome, this.data, this.repeteAno});
  Feriado.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    data = json['data'];
    repeteAno = json['repeteAno'];
  }
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'data': data, 'repeteAno': repeteAno};

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.celebration, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Data", fieldName: "data", icon: Icons.date_range, isInForm: true),
    const FieldConfig(label: "Repete Ano", fieldName: "repeteAno", icon: Icons.repeat, isInForm: true),
  ];
}

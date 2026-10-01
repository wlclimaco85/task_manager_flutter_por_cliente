import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class HorarioFunc {
  int? id;
  String? nome;
  String? tipo;
  bool? ativo;

  HorarioFunc({this.id, this.nome, this.tipo, this.ativo});
  HorarioFunc.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    tipo = json['tipo'];
    ativo = json['ativo'];
  }
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome, 'tipo': tipo, 'ativo': ativo};

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.schedule, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Tipo", fieldName: "tipo", icon: Icons.category, isInForm: true),
    const FieldConfig(label: "Ativo", fieldName: "ativo", icon: Icons.check_circle, isInForm: true),
  ];
}

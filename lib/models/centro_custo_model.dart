import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class CentroCusto {
  int? id;
  String? nome;

  CentroCusto({this.id, this.nome});
  factory CentroCusto.fromJson(Map<String, dynamic> json) => CentroCusto(id: json['id'], nome: json['nome']);
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.account_balance, isInForm: true, isFilterable: true),
  ];
}

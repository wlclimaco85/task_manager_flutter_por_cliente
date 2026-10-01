import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Cargo {
  int? id;
  String? nome;

  Cargo({this.id, this.nome});
  Cargo.fromJson(Map<String, dynamic> json) { id = json['id']; nome = json['nome']; }
  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.work, isInForm: true, isFilterable: true),
  ];
}

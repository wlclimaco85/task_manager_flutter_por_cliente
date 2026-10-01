import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Treino {
  int? id;
  String? nome;
  String? descricao;
  String? dtTreino;
  String? tipo;
  int? duracao;

  Treino({this.id, this.nome, this.descricao, this.dtTreino, this.tipo, this.duracao});

  Treino.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    descricao = json['descricao'];
    dtTreino = json['dtTreino'];
    tipo = json['tipo'];
    duracao = json['duracao'];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'nome': nome, 'descricao': descricao,
    'dtTreino': dtTreino, 'tipo': tipo, 'duracao': duracao,
  };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.fitness_center, isInForm: true, isFilterable: true),
    FieldConfig(label: "Descrição", fieldName: "descricao", icon: Icons.description, isInForm: true),
    FieldConfig(label: "Data Treino", fieldName: "dtTreino", icon: Icons.calendar_month, isInForm: true),
    FieldConfig(label: "Tipo", fieldName: "tipo", icon: Icons.category, isInForm: true, isFilterable: true),
    FieldConfig(label: "Duração (min)", fieldName: "duracao", icon: Icons.timer, isInForm: true),
  ];
}

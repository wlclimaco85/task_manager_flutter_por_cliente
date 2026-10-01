import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class AvaliacaoFisica {
  int? id;
  String? nome;
  String? dtAvaliacao;
  double? peso;
  double? altura;
  double? imc;
  String? observacao;

  AvaliacaoFisica({this.id, this.nome, this.dtAvaliacao, this.peso, this.altura, this.imc, this.observacao});

  AvaliacaoFisica.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    nome = json['nome'];
    dtAvaliacao = json['dtAvaliacao'];
    peso = (json['peso'] as num?)?.toDouble();
    altura = (json['altura'] as num?)?.toDouble();
    imc = (json['imc'] as num?)?.toDouble();
    observacao = json['observacao'];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'nome': nome, 'dtAvaliacao': dtAvaliacao,
    'peso': peso, 'altura': altura, 'imc': imc, 'observacao': observacao,
  };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.person, isInForm: true, isFilterable: true),
    FieldConfig(label: "Data Avaliação", fieldName: "dtAvaliacao", icon: Icons.calendar_month, isInForm: true),
    FieldConfig(label: "Peso (kg)", fieldName: "peso", icon: Icons.monitor_weight, isInForm: true),
    FieldConfig(label: "Altura (m)", fieldName: "altura", icon: Icons.height, isInForm: true),
    FieldConfig(label: "IMC", fieldName: "imc", icon: Icons.analytics, isInForm: true),
    FieldConfig(label: "Observação", fieldName: "observacao", icon: Icons.notes, isInForm: true),
  ];
}

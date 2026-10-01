import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Mensalidade {
  int? id;
  double? valor;
  DateTime? dtPagamento;
  int? alunoId;
  int? planoId;
  String? urlBoleto;

  Mensalidade({
    this.id,
    this.valor,
    this.dtPagamento,
    this.alunoId,
    this.planoId,
    this.urlBoleto,
  });

  Mensalidade.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    valor = (json['valor'] as num?)?.toDouble();
    dtPagamento = json['dtPagamento'] != null
        ? DateTime.parse(json['dtPagamento'])
        : null;
    alunoId = json['alunoId'];
    planoId = json['planoId'];
    urlBoleto = json['urlBoleto'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': valor,
      'dtPagamento': dtPagamento?.toIso8601String(),
      'alunoId': alunoId,
      'planoId': planoId,
      'urlBoleto': urlBoleto,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Data Pagamento",
      fieldName: "dtPagamento",
      icon: Icons.date_range,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Aluno ID",
      fieldName: "alunoId",
      icon: Icons.person,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Plano ID",
      fieldName: "planoId",
      icon: Icons.assignment,
      isInForm: true,
    ),
  ];
}

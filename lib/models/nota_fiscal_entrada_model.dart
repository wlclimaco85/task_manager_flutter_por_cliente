import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class NotaFiscalEntrada {
  int? id;
  String? numero;
  String? fornecedor;
  String? dtEmissao;
  double? valor;
  String? status;

  NotaFiscalEntrada({this.id, this.numero, this.fornecedor, this.dtEmissao, this.valor, this.status});

  NotaFiscalEntrada.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    numero = json['numero'];
    fornecedor = json['fornecedor'];
    dtEmissao = json['dtEmissao'];
    valor = (json['valor'] as num?)?.toDouble();
    status = json['status'];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'numero': numero, 'fornecedor': fornecedor,
    'dtEmissao': dtEmissao, 'valor': valor, 'status': status,
  };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Número", fieldName: "numero", icon: Icons.numbers, isInForm: true, isFilterable: true),
    FieldConfig(label: "Fornecedor", fieldName: "fornecedor", icon: Icons.business, isInForm: true, isFilterable: true),
    FieldConfig(label: "Data Emissão", fieldName: "dtEmissao", icon: Icons.calendar_month, isInForm: true),
    FieldConfig(label: "Valor", fieldName: "valor", icon: Icons.attach_money, isInForm: true),
    FieldConfig(label: "Status", fieldName: "status", icon: Icons.info, isInForm: true, isFilterable: true),
  ];
}

import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class NotaFiscalSaida {
  int? id;
  String? numero;
  String? cliente;
  String? dtEmissao;
  double? valor;
  String? status;

  NotaFiscalSaida({this.id, this.numero, this.cliente, this.dtEmissao, this.valor, this.status});

  NotaFiscalSaida.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    numero = json['numero'];
    cliente = json['cliente'];
    dtEmissao = json['dtEmissao'];
    valor = (json['valor'] as num?)?.toDouble();
    status = json['status'];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'numero': numero, 'cliente': cliente,
    'dtEmissao': dtEmissao, 'valor': valor, 'status': status,
  };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Número", fieldName: "numero", icon: Icons.numbers, isInForm: true, isFilterable: true),
    FieldConfig(label: "Cliente", fieldName: "cliente", icon: Icons.person, isInForm: true, isFilterable: true),
    FieldConfig(label: "Data Emissão", fieldName: "dtEmissao", icon: Icons.calendar_month, isInForm: true),
    FieldConfig(label: "Valor", fieldName: "valor", icon: Icons.attach_money, isInForm: true),
    FieldConfig(label: "Status", fieldName: "status", icon: Icons.info, isInForm: true, isFilterable: true),
  ];
}

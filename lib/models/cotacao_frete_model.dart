import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class CotacaoFrete {
  int? id;
  String? cepRetirada;
  String? cidadeRetirada;
  String? estadoRetirada;
  String? cepEntrega;
  String? cidadeEntrega;
  String? estadoEntrega;
  double? valor;
  String? status;
  int? qtdSacos;

  CotacaoFrete({this.id, this.cepRetirada, this.cidadeRetirada, this.estadoRetirada, this.cepEntrega, this.cidadeEntrega, this.estadoEntrega, this.valor, this.status, this.qtdSacos});

  CotacaoFrete.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    cepRetirada = json['cepRetirada'];
    cidadeRetirada = json['cidadeRetirada'];
    estadoRetirada = json['estadoRetirada'];
    cepEntrega = json['cepEntrega'];
    cidadeEntrega = json['cidadeEntrega'];
    estadoEntrega = json['estadoEntrega'];
    valor = (json['valor'] as num?)?.toDouble();
    status = json['status'];
    qtdSacos = json['qtdSacos'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cepRetirada': cepRetirada,
        'cidadeRetirada': cidadeRetirada,
        'estadoRetirada': estadoRetirada,
        'cepEntrega': cepEntrega,
        'cidadeEntrega': cidadeEntrega,
        'estadoEntrega': estadoEntrega,
        'valor': valor,
        'status': status,
        'qtdSacos': qtdSacos,
      };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "CEP Retirada", fieldName: "cepRetirada", icon: Icons.location_on, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Cidade Retirada", fieldName: "cidadeRetirada", icon: Icons.location_city, isInForm: true),
    const FieldConfig(label: "Estado Retirada", fieldName: "estadoRetirada", icon: Icons.map, isInForm: true),
    const FieldConfig(label: "CEP Entrega", fieldName: "cepEntrega", icon: Icons.location_on, isInForm: true),
    const FieldConfig(label: "Cidade Entrega", fieldName: "cidadeEntrega", icon: Icons.location_city, isInForm: true),
    const FieldConfig(label: "Estado Entrega", fieldName: "estadoEntrega", icon: Icons.map, isInForm: true),
    const FieldConfig(label: "Valor", fieldName: "valor", icon: Icons.attach_money, isInForm: true),
    const FieldConfig(label: "Status", fieldName: "status", icon: Icons.info, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Qtd Sacos", fieldName: "qtdSacos", icon: Icons.inventory, isInForm: true),
  ];
}

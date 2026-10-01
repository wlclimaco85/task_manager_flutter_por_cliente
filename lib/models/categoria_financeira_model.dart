import 'package:flutter/material.dart';

import '../widgets/generic_grid_screen.dart';

class CategoriaFinanceira {
  int? id;
  String? descricao;
  double? valor;

  CategoriaFinanceira({
    this.id,
    this.descricao,
    this.valor,
  });

  factory CategoriaFinanceira.fromJson(Map<String, dynamic> json) {
    return CategoriaFinanceira(
      id: json['id'],
      descricao: json['descricao']?.toString() ?? json['nome']?.toString(),
      valor: (json['valor'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: 'Descrição',
      fieldName: 'descricao',
      icon: Icons.category,
      isInForm: true,
      isFilterable: true,
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: true,
    ),
    const FieldConfig(
      label: 'Valor padrão',
      fieldName: 'valor',
      icon: Icons.attach_money,
      isInForm: true,
      isFilterable: false,
      fieldType: FieldType.currency,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}

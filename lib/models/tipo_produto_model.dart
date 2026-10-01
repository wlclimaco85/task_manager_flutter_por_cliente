import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class TipoProduto {
  int? id;
  String? tipoProduto;

  TipoProduto({this.id, this.tipoProduto});
  TipoProduto.fromJson(Map<String, dynamic> json) { id = json['id']; tipoProduto = json['tipoProduto']; }
  Map<String, dynamic> toJson() => {'id': id, 'tipoProduto': tipoProduto};

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Tipo Produto", fieldName: "tipoProduto", icon: Icons.category, isInForm: true, isFilterable: true),
  ];
}

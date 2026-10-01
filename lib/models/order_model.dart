import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class OrderItem {
  int? id;
  String? acao;
  double? valorCompra;
  double? cotacaoAtual;
  double? lucro;
  String? status;
  String? tipo;
  String? estrategia;
  String? ambiente;
  String? nomeRobo;

  OrderItem({this.id, this.acao, this.valorCompra, this.cotacaoAtual, this.lucro, this.status, this.tipo, this.estrategia, this.ambiente, this.nomeRobo});

  OrderItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    acao = json['acao'];
    valorCompra = (json['valorCompra'] as num?)?.toDouble();
    cotacaoAtual = (json['cotacaoAtual'] as num?)?.toDouble();
    lucro = (json['lucro'] as num?)?.toDouble();
    status = json['status'];
    tipo = json['tipo'];
    estrategia = json['estrategia'];
    ambiente = json['ambiente'];
    nomeRobo = json['nomeRobo'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'acao': acao,
        'valorCompra': valorCompra,
        'cotacaoAtual': cotacaoAtual,
        'lucro': lucro,
        'status': status,
        'tipo': tipo,
        'estrategia': estrategia,
        'ambiente': ambiente,
        'nomeRobo': nomeRobo,
      };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Ação", fieldName: "acao", icon: Icons.trending_up, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Valor Compra", fieldName: "valorCompra", icon: Icons.attach_money, isInForm: true),
    const FieldConfig(label: "Cotação Atual", fieldName: "cotacaoAtual", icon: Icons.show_chart, isInForm: true),
    const FieldConfig(label: "Lucro", fieldName: "lucro", icon: Icons.monetization_on, isInForm: true),
    const FieldConfig(label: "Status", fieldName: "status", icon: Icons.info, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Tipo", fieldName: "tipo", icon: Icons.category, isInForm: true),
    const FieldConfig(label: "Estratégia", fieldName: "estrategia", icon: Icons.psychology, isInForm: true),
    const FieldConfig(label: "Robô", fieldName: "nomeRobo", icon: Icons.smart_toy, isInForm: true),
  ];
}

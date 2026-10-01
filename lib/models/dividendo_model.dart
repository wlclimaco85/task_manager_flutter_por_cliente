import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Dividendo {
  int? id;
  int? ticketId;
  String? acao;
  String? dataRecebimento;
  double? valorPorAcao;
  double? valorTotal;

  Dividendo({this.id, this.ticketId, this.acao, this.dataRecebimento, this.valorPorAcao, this.valorTotal});

  Dividendo.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    ticketId = json['ticketId'];
    acao = json['acao'];
    dataRecebimento = json['dataRecebimento'];
    valorPorAcao = (json['valorPorAcao'] as num?)?.toDouble();
    valorTotal = (json['valorTotal'] as num?)?.toDouble();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketId': ticketId,
        'acao': acao,
        'dataRecebimento': dataRecebimento,
        'valorPorAcao': valorPorAcao,
        'valorTotal': valorTotal,
      };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Ação", fieldName: "acao", icon: Icons.trending_up, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Ticket ID", fieldName: "ticketId", icon: Icons.confirmation_number, isInForm: true),
    const FieldConfig(label: "Data Recebimento", fieldName: "dataRecebimento", icon: Icons.date_range, isInForm: true),
    const FieldConfig(label: "Valor por Ação", fieldName: "valorPorAcao", icon: Icons.attach_money, isInForm: true),
    const FieldConfig(label: "Valor Total", fieldName: "valorTotal", icon: Icons.monetization_on, isInForm: true),
  ];
}

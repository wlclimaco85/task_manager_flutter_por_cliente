import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Pedido {
  int? id;
  String? usuario;
  double? total;
  String? status;
  String? dataPedido;

  Pedido({this.id, this.usuario, this.total, this.status, this.dataPedido});

  Pedido.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    usuario = json['usuario'];
    total = (json['total'] as num?)?.toDouble();
    status = json['status'];
    dataPedido = json['dataPedido'];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'usuario': usuario,
        'total': total,
        'status': status,
        'dataPedido': dataPedido,
      };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Usuário", fieldName: "usuario", icon: Icons.person, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Total", fieldName: "total", icon: Icons.attach_money, isInForm: true),
    const FieldConfig(label: "Status", fieldName: "status", icon: Icons.info, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Data Pedido", fieldName: "dataPedido", icon: Icons.date_range, isInForm: true),
  ];
}

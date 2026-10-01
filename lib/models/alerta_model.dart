import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Alerta {
  int? id;
  String? titulo;
  String? mensagem;
  String? tipo;
  String? dtAlerta;
  bool? lido;

  Alerta({this.id, this.titulo, this.mensagem, this.tipo, this.dtAlerta, this.lido});

  Alerta.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    titulo = json['titulo'];
    mensagem = json['mensagem'];
    tipo = json['tipo'];
    dtAlerta = json['dtAlerta'];
    lido = json['lido'];
  }

  Map<String, dynamic> toJson() => {
    'id': id, 'titulo': titulo, 'mensagem': mensagem,
    'tipo': tipo, 'dtAlerta': dtAlerta, 'lido': lido,
  };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Título", fieldName: "titulo", icon: Icons.title, isInForm: true, isFilterable: true),
    FieldConfig(label: "Mensagem", fieldName: "mensagem", icon: Icons.message, isInForm: true),
    FieldConfig(label: "Tipo", fieldName: "tipo", icon: Icons.category, isInForm: true, isFilterable: true),
    FieldConfig(label: "Data Alerta", fieldName: "dtAlerta", icon: Icons.calendar_today, isInForm: true),
    FieldConfig(label: "Lido", fieldName: "lido", icon: Icons.check_circle, isInForm: true),
  ];
}

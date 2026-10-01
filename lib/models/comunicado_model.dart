import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Comunicado {
  int? id;
  String? titulo;
  String? conteudo;
  String? autor;
  int? codApp;
  int? empId;
  String? dataPublicacao;

  Comunicado({
    this.id, this.titulo, this.conteudo, this.autor,
    this.codApp, this.empId, this.dataPublicacao,
  });

  Comunicado.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    titulo = json['titulo'];
    conteudo = json['conteudo'];
    autor = json['autor'];
    codApp = json['codApp'];
    empId = json['empId'];
    dataPublicacao = json['dataPublicacao'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'conteudo': conteudo,
    'autor': autor,
    'codApp': codApp,
    'empId': empId,
    'dataPublicacao': dataPublicacao,
  };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Título", fieldName: "titulo", icon: Icons.title, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Conteúdo", fieldName: "conteudo", icon: Icons.description, isInForm: true, isFilterable: false, fieldType: FieldType.multiline),
    const FieldConfig(label: "Autor", fieldName: "autor", icon: Icons.person, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Data Publicação", fieldName: "dataPublicacao", icon: Icons.calendar_today, isInForm: false, isFilterable: false),
  ];
}

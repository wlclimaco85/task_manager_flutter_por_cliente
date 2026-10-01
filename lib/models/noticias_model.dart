import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

// Classe legada usada por task_screen.dart e newsDetailScreen.dart
class Data {
  int? id;
  String? titulo;
  String? tituloResu;
  String? resumo;
  String? noticia;
  String? autor;
  String? fonte;
  String? link;
  int? codApp;
  DateTime? dtNoticia;

  Data({
    this.id, this.titulo, this.tituloResu, this.resumo, this.noticia,
    this.autor, this.fonte, this.link, this.codApp, this.dtNoticia,
  });

  Data.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    titulo = json['titulo'];
    tituloResu = json['tituloResu'];
    resumo = json['resumo'];
    noticia = json['noticia'];
    autor = json['autor'];
    fonte = json['fonte'];
    link = json['link'];
    codApp = json['codApp'];
    dtNoticia = json['dtNoticia'] != null ? DateTime.tryParse(json['dtNoticia']) : null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'tituloResu': tituloResu,
    'resumo': resumo,
    'noticia': noticia,
    'autor': autor,
    'fonte': fonte,
    'link': link,
    'codApp': codApp,
    'dtNoticia': dtNoticia?.toIso8601String(),
  };

  static List<Data> fromJsonList(List<dynamic> list) =>
      list.map((e) => Data.fromJson(e as Map<String, dynamic>)).toList();
}

// Alias para compatibilidade
typedef NoticiaData = Data;

class Noticia {
  int? id;
  String? titulo;
  String? resumo;
  String? noticia;
  String? autor;
  String? fonte;
  String? link;
  int? codApp;
  String? dtNoticia;

  Noticia({
    this.id, this.titulo, this.resumo, this.noticia,
    this.autor, this.fonte, this.link, this.codApp, this.dtNoticia,
  });

  Noticia.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    titulo = json['titulo'];
    resumo = json['resumo'];
    noticia = json['noticia'];
    autor = json['autor'];
    fonte = json['fonte'];
    link = json['link'];
    codApp = json['codApp'];
    dtNoticia = json['dtNoticia'];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'titulo': titulo,
    'resumo': resumo,
    'noticia': noticia,
    'autor': autor,
    'fonte': fonte,
    'link': link,
    'codApp': codApp,
    'dtNoticia': dtNoticia,
  };

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(label: "Título", fieldName: "titulo", icon: Icons.title, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Resumo", fieldName: "resumo", icon: Icons.short_text, isInForm: true, isFilterable: false),
    const FieldConfig(label: "Notícia", fieldName: "noticia", icon: Icons.article, isInForm: true, isFilterable: false),
    const FieldConfig(label: "Autor", fieldName: "autor", icon: Icons.person, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Fonte", fieldName: "fonte", icon: Icons.source, isInForm: true, isFilterable: true),
    const FieldConfig(label: "Link", fieldName: "link", icon: Icons.link, isInForm: true, isFilterable: false),
    const FieldConfig(label: "Data", fieldName: "dtNoticia", icon: Icons.calendar_today, isInForm: true, isFilterable: false),
  ];
}

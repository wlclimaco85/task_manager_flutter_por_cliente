import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Dieta {
  int? id;
  int? codAluno; // simplificado
  String? nutricionista;
  String? objetivo;
  String? descricao;
  String? dtConsulta;
  String? dtInicio;
  String? dtFinal;

  Dieta({
    this.id,
    this.codAluno,
    this.nutricionista,
    this.objetivo,
    this.descricao,
    this.dtConsulta,
    this.dtInicio,
    this.dtFinal,
  });

  Dieta.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    codAluno = json['codAluno'];
    nutricionista = json['nutricionista'];
    objetivo = json['objetivo'];
    descricao = json['descricao'];
    dtConsulta = json['dtConsulta'];
    dtInicio = json['dtInicio'];
    dtFinal = json['dtFinal'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codAluno': codAluno,
      'nutricionista': nutricionista,
      'objetivo': objetivo,
      'descricao': descricao,
      'dtConsulta': dtConsulta,
      'dtInicio': dtInicio,
      'dtFinal': dtFinal,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nutricionista",
      fieldName: "nutricionista",
      icon: Icons.person,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Objetivo",
      fieldName: "objetivo",
      icon: Icons.flag,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Data Consulta",
      fieldName: "dtConsulta",
      icon: Icons.calendar_month,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Data Início",
      fieldName: "dtInicio",
      icon: Icons.calendar_today,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Data Final",
      fieldName: "dtFinal",
      icon: Icons.calendar_today,
      isInForm: true,
    ),
  ];
}

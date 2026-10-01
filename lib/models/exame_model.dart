import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Exame {
  int? id;
  int? idaluno;
  String? nome;
  String? laboratorio;
  String? medico;
  String? resultado;
  String? dtExame;
  String? dtEntregaResulExame;

  Exame({
    this.id,
    this.idaluno,
    this.nome,
    this.laboratorio,
    this.medico,
    this.resultado,
    this.dtExame,
    this.dtEntregaResulExame,
  });

  Exame.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    idaluno = json['idaluno'];
    nome = json['nome'];
    laboratorio = json['laboratorio'];
    medico = json['medico'];
    resultado = json['resultado'];
    dtExame = json['dtExame'];
    dtEntregaResulExame = json['dtEntregaResulExame'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idaluno': idaluno,
      'nome': nome,
      'laboratorio': laboratorio,
      'medico': medico,
      'resultado': resultado,
      'dtExame': dtExame,
      'dtEntregaResulExame': dtEntregaResulExame,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.text_fields,
      isInForm: true,
      isFilterable: true,
    ),
    const FieldConfig(
      label: "Laboratório",
      fieldName: "laboratorio",
      icon: Icons.local_hospital,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Médico",
      fieldName: "medico",
      icon: Icons.person,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Resultado",
      fieldName: "resultado",
      icon: Icons.description,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Data Exame",
      fieldName: "dtExame",
      icon: Icons.calendar_month,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Entrega Resultado",
      fieldName: "dtEntregaResulExame",
      icon: Icons.event,
      isInForm: true,
    ),
  ];
}

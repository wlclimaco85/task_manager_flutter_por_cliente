import 'package:flutter/material.dart';
import '../../../widgets/generic_grid_screen.dart';

class Alimento {
  String? id;
  String? nome;
  String? grupoAlimentar;
  double? calorias;
  double? proteinas;
  double? carboidratos;
  double? gorduras;
  bool? ativo;

  Alimento({
    this.id,
    this.nome,
    this.grupoAlimentar,
    this.calorias,
    this.proteinas,
    this.carboidratos,
    this.gorduras,
    this.ativo,
  });

  // Construtor para criar a instância a partir de um JSON
  factory Alimento.fromJson(Map<String, dynamic> json) {
    return Alimento(
      id: json['id']?.toString(),
      nome: json['nome']?.toString(),
      grupoAlimentar: json['grupoAlimentar']?.toString(),
      calorias: json['calorias'] != null
          ? double.tryParse(json['calorias'].toString())
          : null,
      proteinas: json['proteinas'] != null
          ? double.tryParse(json['proteinas'].toString())
          : null,
      carboidratos: json['carboidratos'] != null
          ? double.tryParse(json['carboidratos'].toString())
          : null,
      gorduras: json['gorduras'] != null
          ? double.tryParse(json['gorduras'].toString())
          : null,
      ativo: json['ativo'] == null
          ? null
          : json['ativo'] == true || json['ativo'] == 1,
    );
  }

  // Converte a instância para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'grupoAlimentar': grupoAlimentar,
      'calorias': calorias,
      'proteinas': proteinas,
      'carboidratos': carboidratos,
      'gorduras': gorduras,
      'ativo': ativo,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "ID",
      fieldName: "id",
      icon: Icons.numbers,
      isFilterable: true,
      isInForm: false,
    ),
    FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.fastfood,
      isFilterable: true,
      isInForm: true,
      isRequired: true,
      validator: (value) {
        if (value == null || value.isEmpty) return 'Nome é obrigatório';
        return null;
      },
    ),
    const FieldConfig(
      label: "Grupo Alimentar",
      fieldName: "grupoAlimentar",
      icon: Icons.category,
      isFilterable: true,
      isInForm: true,
    ),
    const FieldConfig(
      label: "Calorias",
      fieldName: "calorias",
      icon: Icons.local_fire_department,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Proteínas",
      fieldName: "proteinas",
      icon: Icons.fitness_center,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Carboidratos",
      fieldName: "carboidratos",
      icon: Icons.grain,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Gorduras",
      fieldName: "gorduras",
      icon: Icons.opacity,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.number,
    ),
    const FieldConfig(
      label: "Ativo",
      fieldName: "ativo",
      icon: Icons.check_circle,
      isFilterable: true,
      isInForm: true,
      fieldType: FieldType.boolean,
    ),
  ];
}

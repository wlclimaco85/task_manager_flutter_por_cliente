import 'package:flutter/material.dart';
import '../customization/generic_grid_card.dart';

class FuncionarioModel {
  int? id;
  // ── herdado de Parceiro ──
  String? nome;
  String? cpf;
  String? email;
  String? telefone1;
  String? rg;
  // ── específico ──
  String? matricula;
  String? pis;
  String? ctps;
  String? sexo;
  String? dataNascimento;
  String? dataAdmissao;
  String? dataDemissao;
  String? motivoDemissao;
  bool? ativo;
  double? salario;
  double? salarioBase;
  int? cargaHorariaSemanal;
  // ── FKs ──
  Map<String, dynamic>? empresa;
  Map<String, dynamic>? cargo;
  Map<String, dynamic>? departamento;
  Map<String, dynamic>? horarioFunc;
  Map<String, dynamic>? login;

  FuncionarioModel({
    this.id, this.nome, this.cpf, this.email, this.telefone1, this.rg,
    this.matricula, this.pis, this.ctps, this.sexo,
    this.dataNascimento, this.dataAdmissao, this.dataDemissao, this.motivoDemissao,
    this.ativo, this.salario, this.salarioBase, this.cargaHorariaSemanal,
    this.empresa, this.cargo, this.departamento, this.horarioFunc, this.login,
  });

  factory FuncionarioModel.fromJson(Map<String, dynamic> json) {
    return FuncionarioModel(
      id: json['id'],
      nome: json['nome']?.toString(),
      cpf: json['cpf']?.toString(),
      email: json['email']?.toString(),
      telefone1: json['telefone1']?.toString(),
      rg: json['rg']?.toString(),
      matricula: json['matricula']?.toString(),
      pis: json['pis']?.toString(),
      ctps: json['ctps']?.toString(),
      sexo: json['sexo']?.toString(),
      dataNascimento: json['dataNascimento']?.toString(),
      dataAdmissao: json['dataAdmissao']?.toString(),
      dataDemissao: json['dataDemissao']?.toString(),
      motivoDemissao: json['motivoDemissao']?.toString(),
      ativo: json['ativo'] as bool?,
      salario: (json['salario'] as num?)?.toDouble(),
      salarioBase: (json['salarioBase'] as num?)?.toDouble(),
      cargaHorariaSemanal: json['cargaHorariaSemanal'] as int?,
      empresa: json['empresa'] is Map ? Map<String, dynamic>.from(json['empresa']) : null,
      cargo: json['cargo'] is Map ? Map<String, dynamic>.from(json['cargo']) : null,
      departamento: json['departamento'] is Map ? Map<String, dynamic>.from(json['departamento']) : null,
      horarioFunc: json['horarioFunc'] is Map ? Map<String, dynamic>.from(json['horarioFunc']) : null,
      login: json['login'] is Map ? Map<String, dynamic>.from(json['login']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'nome': nome,
    'cpf': cpf,
    'email': email,
    'telefone1': telefone1,
    'rg': rg,
    'matricula': matricula,
    'pis': pis,
    'ctps': ctps,
    'sexo': sexo,
    'dataNascimento': dataNascimento,
    'dataAdmissao': dataAdmissao,
    'dataDemissao': dataDemissao,
    'motivoDemissao': motivoDemissao,
    'ativo': ativo,
    'salario': salario,
    'salarioBase': salarioBase,
    'cargaHorariaSemanal': cargaHorariaSemanal,
    if (empresa != null) 'empresa': empresa,
    if (cargo != null) 'cargo': cargo,
    if (departamento != null) 'departamento': departamento,
    if (horarioFunc != null) 'horarioFunc': horarioFunc,
    if (login != null) 'login': login,
    'tipoCliente': 'FUNCIONARIO',
  };

  static const List<FieldConfig> fieldConfigs = [
    FieldConfig(label: "Nome", fieldName: "nome", icon: Icons.person, isInForm: true, isFilterable: true),
    FieldConfig(label: "CPF", fieldName: "cpf", icon: Icons.badge, isInForm: true, isFilterable: true, fieldType: FieldType.cpf),
    FieldConfig(label: "E-mail", fieldName: "email", icon: Icons.email, isInForm: true, fieldType: FieldType.email),
    FieldConfig(label: "Telefone", fieldName: "telefone1", icon: Icons.phone, isInForm: true, fieldType: FieldType.phone),
    FieldConfig(label: "Matrícula", fieldName: "matricula", icon: Icons.numbers, isInForm: true, isFilterable: true),
    FieldConfig(label: "PIS", fieldName: "pis", icon: Icons.credit_card, isInForm: true),
    FieldConfig(label: "CTPS", fieldName: "ctps", icon: Icons.work, isInForm: true),
    FieldConfig(label: "RG", fieldName: "rg", icon: Icons.badge, isInForm: true),
    FieldConfig(label: "Sexo", fieldName: "sexo", icon: Icons.wc, isInForm: true,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'M', 'label': 'Masculino'},
        {'value': 'F', 'label': 'Feminino'},
        {'value': 'O', 'label': 'Outro'},
      ],
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    FieldConfig(label: "Dt. Nascimento", fieldName: "dataNascimento", icon: Icons.cake, isInForm: true, fieldType: FieldType.date),
    FieldConfig(label: "Dt. Admissão", fieldName: "dataAdmissao", icon: Icons.calendar_today, isInForm: true, isFilterable: true, fieldType: FieldType.date),
    FieldConfig(label: "Salário", fieldName: "salario", icon: Icons.attach_money, isInForm: true, fieldType: FieldType.currency),
    FieldConfig(label: "Carga Horária/Sem.", fieldName: "cargaHorariaSemanal", icon: Icons.schedule, isInForm: true, fieldType: FieldType.number),
    // Campos só no update (isInForm: false oculta no insert)
    FieldConfig(label: "Ativo", fieldName: "ativo", icon: Icons.check_circle, isInForm: false, isFilterable: true, fieldType: FieldType.boolean),
    FieldConfig(label: "Dt. Demissão", fieldName: "dataDemissao", icon: Icons.event_busy, isInForm: false, fieldType: FieldType.date),
    FieldConfig(label: "Motivo Demissão", fieldName: "motivoDemissao", icon: Icons.info, isInForm: false, fieldType: FieldType.multiline),
  ];
}

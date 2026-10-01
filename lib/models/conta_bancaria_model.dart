import 'package:flutter/material.dart';
import '../customization/generic_grid_card.dart';
import '../models/empresa_model.dart';
import '../models/parceiro_model.dart';

class ContaBancaria {
  int? id;
  String? banco;
  String? agencia;
  String? numero;
  String? descricao;
  String? tipo;
  double? saldoInicial;
  DateTime? dataAbertura;
  double? saldoAtual;
  Empresa empresa;
  Parceiro? parceiro;
  bool ativo;

  ContaBancaria({
    this.id,
    this.banco,
    this.agencia,
    this.numero,
    this.descricao,
    this.tipo,
    this.saldoInicial,
    this.dataAbertura,
    this.saldoAtual,
    required this.empresa,
    this.parceiro,
    this.ativo = true,
  });

  factory ContaBancaria.fromJson(Map<String, dynamic> json) {
    final saldoIni = (json['saldoInicial'] ?? json['saldo_inicial'] ?? 0).toDouble();
    final saldoAtu = (json['saldoAtual'] ?? json['saldo_atual'] ?? json['saldoInicial'] ?? json['saldo_inicial'] ?? 0).toDouble();
    return ContaBancaria(
      id: json['id'],
      banco: json['banco'],
      agencia: json['agencia'],
      numero: json['numero'],
      descricao: json['descricao'],
      tipo: json['tipo'] ?? 'CONTA_CORRENTE',
      saldoInicial: saldoIni,
      dataAbertura: json['dataAbertura'] != null
          ? DateTime.tryParse(json['dataAbertura'].toString())
          : (json['data_abertura'] != null ? DateTime.tryParse(json['data_abertura'].toString()) : null),
      saldoAtual: saldoAtu,
      empresa: json['empresa'] is Map
          ? Empresa.fromJson(Map<String, dynamic>.from(json['empresa']))
          : Empresa(
              id: json['empresaId'] ?? json['empresa_id'] ?? (json['empresa'] is int ? json['empresa'] : null),
              nome: json['empresaNome'] ?? json['empresa_nome'] ?? '',
            ),
      parceiro: json['parceiro'] is Map
          ? Parceiro.fromJson(Map<String, dynamic>.from(json['parceiro']))
          : ((json['parceiroId'] != null ||
                  json['parceiro_id'] != null ||
                  json['parceiroNome'] != null ||
                  json['parceiro_nome'] != null ||
                  json['parceiro'] != null)
              ? Parceiro(
                  id: json['parceiroId'] ??
                      json['parceiro_id'] ??
                      (json['parceiro'] is int ? json['parceiro'] : null),
                  nome: json['parceiroNome'] ??
                      json['parceiro_nome'] ??
                      (json['parceiro'] is String ? json['parceiro'] : null) ??
                      '',
                )
              : null),
      ativo: json['ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'banco': banco,
      'agencia': agencia,
      'numero': numero,
      'descricao': descricao,
      'tipo': tipo,
      'saldoInicial': saldoInicial,
      'dataAbertura': dataAbertura?.toIso8601String(),
      'saldoAtual': saldoAtual,
      'empresa': empresa.toJson(),
      'empresaNome': empresa.nome,
      'empresaId': empresa.id,
      if (parceiro != null)
        'parceiro': {
          'id': parceiro!.id,
          'nome': parceiro!.nome ?? parceiro!.razaoSocial ?? '',
        },
      if (parceiro != null) 'parceiroId': parceiro!.id,
      if (parceiro != null)
        'parceiroNome': parceiro!.nome ?? parceiro!.razaoSocial ?? '',
      'ativo': ativo,
    };
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "Banco",
      fieldName: "banco",
      icon: Icons.account_balance,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
      isRequired: true,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Agência",
      fieldName: "agencia",
      icon: Icons.business,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Número",
      fieldName: "numero",
      icon: Icons.numbers,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      isRequired: true,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.text,
    ),
    const FieldConfig(
      label: "Tipo",
      fieldName: "tipo",
      icon: Icons.category,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      isRequired: true,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'CONTA_CORRENTE', 'label': 'Conta Corrente'},
        {'value': 'POUPANCA', 'label': 'Poupança'},
        {'value': 'CAIXA', 'label': 'Caixa'},
        {'value': 'CARTEIRA', 'label': 'Carteira'},
        {'value': 'INVESTIMENTO', 'label': 'Investimento'},
      ],
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const FieldConfig(
      label: "Saldo Inicial",
      fieldName: "saldoInicial",
      icon: Icons.savings,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      isRequired: true,
      fieldType: FieldType.currency,
    ),
    const FieldConfig(
      label: "Data Abertura",
      fieldName: "dataAbertura",
      icon: Icons.event,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      isRequired: true,
      fieldType: FieldType.date,
    ),
    const FieldConfig(
      label: "Saldo Atual",
      fieldName: "saldoAtual",
      icon: Icons.monetization_on,
      isInForm: false,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.currency,
    ),
    const FieldConfig(
      label: "Empresa",
      fieldName: "empresa",
      displayFieldName: "empresa.nome",
      icon: Icons.business,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      isRequired: true,
      fieldType: FieldType.dropdown,
    ),
    const FieldConfig(
      label: "Parceiro",
      fieldName: "parceiro",
      displayFieldName: "parceiro.nome",
      icon: Icons.person,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
    ),
    const FieldConfig(
      label: "Ativo",
      fieldName: "ativo",
      icon: Icons.toggle_on,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.boolean,
    ),
  ];
}


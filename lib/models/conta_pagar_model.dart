import 'package:flutter/material.dart';
import '../../../utils/api_links.dart';
import '../../services/parceiro_caller.dart';
import '../../services/formaPagamento_caller.dart';
import '../../services/network_caller.dart';
import '../customization/generic_grid_card.dart';
import 'audit_model.dart';
import 'categoria_financeira_model.dart';
import 'centro_custo_model.dart';
import 'conta_bancaria_model.dart';
import 'empresa_model.dart';
import 'file_attachment_model.dart';
import 'forma_pagamento_model.dart';
import 'parceiro_model.dart';
import '../widgets/finance/financial_lookup_loader.dart';

enum StatusConta { ABERTA, BAIXADA, CANCELADA }

class ContaPagar {
  int? id;
  String descricao;
  double valor;
  DateTime dataVencimento;
  DateTime? dataBaixa;
  double? valorBaixa;
  double? valorMulta;
  double? valorJuros;
  double? valorDesconto;
  StatusConta status;
  Empresa empresa;
  Parceiro? parceiro;
  Parceiro? parceiroDev;
  FileAttachment? file;
  FormaPagamento? formaPagamento;
  CategoriaFinanceira? categoriaFinanceira;
  CentroCusto? centroCusto;
  Audit audit;
  ContaBancaria? contaBaixa;

  /// Quantidade de anexos vinculados (vem da listagem do backend). 0 = sem anexo.
  int qtdAnexos;

  ContaPagar({
    this.id,
    required this.descricao,
    required this.valor,
    required this.dataVencimento,
    this.dataBaixa,
    this.valorBaixa,
    this.valorMulta,
    this.valorJuros,
    this.valorDesconto,
    required this.status,
    required this.empresa,
    this.parceiro,
    this.parceiroDev,
    this.file,
    this.formaPagamento,
    this.categoriaFinanceira,
    this.centroCusto,
    required this.audit,
    this.contaBaixa,
    this.qtdAnexos = 0,
  });

  factory ContaPagar.fromJson(Map<String, dynamic> json) {
    return ContaPagar(
      id: json['id'],
      descricao: json['descricao'],
      valor: json['valor']?.toDouble() ?? 0.0,
      dataVencimento: DateTime.parse(json['dataVencimento']),
      dataBaixa:
          json['dataBaixa'] != null ? DateTime.parse(json['dataBaixa']) : null,
      valorBaixa: json['valorBaixa']?.toDouble(),
      valorMulta: json['valorMulta']?.toDouble(),
      valorJuros: json['valorJuros']?.toDouble(),
      valorDesconto: json['valorDesconto']?.toDouble(),
      status: _parseStatus(json['status']),
      empresa: json['empresa'] != null
          ? Empresa.fromJson(json['empresa'])
          : Empresa(),
      parceiro:
          json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null,
      parceiroDev: json['parceiroDev'] != null
          ? Parceiro.fromJson(json['parceiroDev'])
          : null,
      file: json['file'] != null ? FileAttachment.fromJson(json['file']) : null,
      formaPagamento: json['formaPagamento'] != null
          ? FormaPagamento.fromJson(json['formaPagamento'])
          : null,
      categoriaFinanceira: _parseCategoriaFinanceira(json),
      centroCusto: _parseCentroCusto(json),
      audit: Audit.fromJson(json['audit'] ?? {}),
      contaBaixa: json['contaBaixa'] != null
          ? ContaBancaria.fromJson(json['contaBaixa'])
          : null,
      qtdAnexos: (json['qtdAnexos'] as num?)?.toInt() ?? 0,
    );
  }

  static StatusConta _parseStatus(dynamic status) {
    if (status is int) {
      switch (status) {
        case 0:
          return StatusConta.ABERTA;
        case 1:
          return StatusConta.BAIXADA;
        case 2:
          return StatusConta.CANCELADA;
        default:
          return StatusConta.ABERTA;
      }
    } else if (status is String) {
      switch (status) {
        case 'ABERTA':
          return StatusConta.ABERTA;
        case 'BAIXADA':
          return StatusConta.BAIXADA;
        case 'CANCELADA':
          return StatusConta.CANCELADA;
        default:
          return StatusConta.ABERTA;
      }
    } else {
      return StatusConta.ABERTA;
    }
  }

  int _statusToInt(StatusConta status) {
    switch (status) {
      case StatusConta.ABERTA:
        return 0;
      case StatusConta.BAIXADA:
        return 1;
      case StatusConta.CANCELADA:
        return 2;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descricao': descricao,
      'valor': valor,
      'dataVencimento': dataVencimento.toIso8601String(),
      'dataBaixa': dataBaixa?.toIso8601String(),
      'valorBaixa': valorBaixa,
      'valorMulta': valorMulta,
      'valorJuros': valorJuros,
      'valorDesconto': valorDesconto,
      'status': _statusToInt(status),
      'empresa': empresa.toJson(),
      'parceiro': parceiro?.toJson(),
      'parceiroDev': parceiroDev?.toJson(),
      'file': file?.toJson(),
      'formaPagamento': formaPagamento?.toJson(),
      'categoriaFinanceira': categoriaFinanceira?.toJson(),
      'centroCusto': centroCusto?.toJson(),
      'audit': audit.toJson(),
      'contaBaixa': contaBaixa?.toJson(),
    };
  }

  static List<FieldConfig> fieldConfigs = [
    FieldConfig(
      label: "Parceiro",
      fieldName: "parceiro.id",
      displayFieldName: "parceiro.nome",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await ParceiroCaller().fetchParceiroDropdown(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Valor",
      fieldName: "valor",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.currency,
    ),
    const FieldConfig(
      label: "Data Vencimento",
      fieldName: "dataVencimento",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.date,
    ),
    const FieldConfig(
      label: "Valor Multa",
      fieldName: "valorMulta",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.currency,
    ),
    const FieldConfig(
      label: "Valor Juros",
      fieldName: "valorJuros",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.currency,
    ),
    const FieldConfig(
      label: "Valor Desconto",
      fieldName: "valorDesconto",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
      fieldType: FieldType.currency,
    ),
    FieldConfig(
      label: "Forma Pagamento",
      fieldName: "formaPagamento.id",
      displayFieldName: "formaPagamento.nome",
      icon: Icons.payment,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await FormaPagamentoCaller().fetchFormasPagamentoDropDown(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: false,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Categoria Financeira",
      fieldName: "categoriaFinanceira.id",
      displayFieldName: "categoriaFinanceira.descricao",
      icon: Icons.category,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await FinancialLookupLoader.loadCategoriasFinanceiras(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: false,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Centro de Custo",
      fieldName: "centroCusto.id",
      displayFieldName: "centroCusto.nome",
      icon: Icons.account_tree,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await FinancialLookupLoader.loadCentrosCusto(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: false,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    // NFe — dropdown de pesquisa (NF-e de entrada para contas a pagar)
    FieldConfig(
      label: "NF-e",
      fieldName: "nfeId",
      displayFieldName: "nfe.numero",
      icon: Icons.receipt,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async =>
          await _loadNfeEntrada(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: false,
      isVisibleByDefault: false,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Anexo",
      fieldName: "file",
      fieldType: FieldType.file,
      icon: Icons.attach_file,
      isInForm: true,
      isVisibleByDefault: false,
      isFixed: false,
    ),
  ];

  static Future<List<Map<String, dynamic>>> _loadNfeEntrada() async {
    final response = await NetworkCaller().getRequest(ApiLinks.allNotasFiscaisEntrada);
    if (response.isSuccess && response.body != null) {
      final lista = (response.body!['data']?['dados'] ?? response.body!['data'] ?? []) as List;
      return lista.map((e) => {'value': e['id'].toString(), 'label': 'NF ${e['numero'] ?? e['id']}'}).toList();
    }
    return [];
  }

  static CategoriaFinanceira? _parseCategoriaFinanceira(Map<String, dynamic> json) {
    final raw = json['categoriaFinanceira'] ?? json['classificacao'];
    if (raw is Map) {
      return CategoriaFinanceira.fromJson(Map<String, dynamic>.from(raw));
    }

    final rawId = json['categoriaFinanceiraId'] ?? json['classificacaoId'];
    if (rawId != null) {
      return CategoriaFinanceira(id: rawId is num ? rawId.toInt() : int.tryParse(rawId.toString()));
    }

    return null;
  }

  static CentroCusto? _parseCentroCusto(Map<String, dynamic> json) {
    final raw = json['centroCusto'] ?? json['centro_custo'];
    if (raw is Map) {
      return CentroCusto.fromJson(Map<String, dynamic>.from(raw));
    }

    final rawId = json['centroCustoId'] ?? json['centro_custo_id'];
    if (rawId != null) {
      return CentroCusto(id: rawId is num ? rawId.toInt() : int.tryParse(rawId.toString()));
    }

    return null;
  }
}

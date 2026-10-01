import 'package:flutter/material.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

import '../customization/generic_grid_card.dart';
import 'regime_tributario_model.dart';
import 'setor_model.dart';

class ObrigacaoFiscal {
  int? id;
  String codigo;
  String descricao;
  int? diaVencimento;
  String? periodicidade;
  bool? ativo;
  bool? gerChamado;
  bool? gerFinanceiro;
  double? valorTributo;
  RegimeTributario? regimeTributario;
  Setor? setor;
  String? statusEnvio;
  String? protocoloEnvio;
  DateTime? dataUltimoEnvio;
  DateTime? proximoLembreteEm;
  int? quantidadeEnvios;
  String? canalEnvio;
  String? mensagemEnvio;

  ObrigacaoFiscal({
    this.id,
    required this.codigo,
    required this.descricao,
    this.diaVencimento,
    this.periodicidade,
    this.ativo,
    this.gerChamado,
    this.gerFinanceiro,
    this.valorTributo,
    this.regimeTributario,
    this.setor,
    this.statusEnvio,
    this.protocoloEnvio,
    this.dataUltimoEnvio,
    this.proximoLembreteEm,
    this.quantidadeEnvios,
    this.canalEnvio,
    this.mensagemEnvio,
  });

  factory ObrigacaoFiscal.fromJson(Map<String, dynamic> json) {
    return ObrigacaoFiscal(
      id: json['id'],
      codigo: json['codigo']?.toString() ?? '',
      descricao: json['descricao']?.toString() ?? '',
      // API retorna snake_case: dia_vencimento
      diaVencimento: (json['dia_vencimento'] ?? json['diaVencimento'] as num?)?.toInt(),
      periodicidade: json['periodicidade']?.toString(),
      ativo: json['ativo'] as bool?,
      gerChamado: json['gerChamado'] as bool?,
      gerFinanceiro: json['gerFinanceiro'] as bool?,
      valorTributo: (json['valorTributo'] as num?)?.toDouble(),
      regimeTributario: json['regimeTributario'] != null
          ? RegimeTributario.fromJson(json['regimeTributario'])
          : null,
      setor: json['setor'] != null ? Setor.fromJson(json['setor']) : null,
      statusEnvio: json['statusEnvio']?.toString() ?? json['status_envio']?.toString(),
      protocoloEnvio:
          json['protocoloEnvio']?.toString() ?? json['protocolo_envio']?.toString(),
      dataUltimoEnvio: _parseDateTime(
        json['dataUltimoEnvio'] ?? json['data_ultimo_envio'],
      ),
      proximoLembreteEm: _parseDateTime(
        json['proximoLembreteEm'] ?? json['proximo_lembrete_em'],
      ),
      quantidadeEnvios: (json['quantidadeEnvios'] ??
              json['quantidade_envios'] as num?)
          ?.toInt(),
      canalEnvio: json['canalEnvio']?.toString() ?? json['canal_envio']?.toString(),
      mensagemEnvio:
          json['mensagemEnvio']?.toString() ?? json['mensagem_envio']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'descricao': descricao,
      'dia_vencimento': diaVencimento,
      'diaVencimento': diaVencimento,
      'periodicidade': periodicidade,
      'ativo': ativo,
      'gerChamado': gerChamado,
      'gerFinanceiro': gerFinanceiro,
      'valorTributo': valorTributo,
      'regimeTributario': regimeTributario != null ? {
        'id': regimeTributario!.id,
        'codigo': regimeTributario!.codigo,
        'descricao': regimeTributario!.descricao,
      } : null,
      'setor': setor != null ? {
        'id': setor!.id,
        'descricao': setor!.nome,
        'nome': setor!.nome,
      } : null,
      'statusEnvio': statusEnvio,
      'protocoloEnvio': protocoloEnvio,
      'dataUltimoEnvio': dataUltimoEnvio?.toIso8601String(),
      'proximoLembreteEm': proximoLembreteEm?.toIso8601String(),
      'quantidadeEnvios': quantidadeEnvios,
      'canalEnvio': canalEnvio,
      'mensagemEnvio': mensagemEnvio,
    };
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  // Classes auxiliares para as entidades relacionadas
  static Future<List<Map<String, dynamic>>> loadFormasPagamento() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allRegimetributario,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {'value': item['id'], 'label': item['codigo'].toString()},
          )
          .toList();
    }
    return [];
  }

  // Classes auxiliares para as entidades relacionadas
  static Future<List<Map<String, dynamic>>> loadSetores() async {
    final NetworkResponse response = await NetworkCaller().getRequest(
      ApiLinks.allSetores,
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['account'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'],
              'label': item['descricao'].toString(),
            },
          )
          .toList();
    }
    return [];
  }

  static List<FieldConfig> fieldConfigs = [
    const FieldConfig(
      label: "ID",
      fieldName: "id",
      icon: Icons.key,
      isInForm: false,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
    ),
    const FieldConfig(
      label: "Codigo",
      fieldName: "codigo",
      icon: Icons.attach_money,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descricao",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Periodicidade",
      fieldName: "periodicidade",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'MENSAL', 'label': 'Mensal'},
        {'value': 'TRIMESTRAL', 'label': 'Trimestral'},
        {'value': 'SEMESTRAL', 'label': 'Semestral'},
        {'value': 'ANUAL', 'label': 'Anual'},
      ], //('MENSAL', 'TRIMESTRAL', 'ANUAL', 'SEMESTRAL'))
      dropdownSelectedValue: 'MENSAL', // Valor padrão selecionado
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true, // Altere para false se não for obrigatório
    ),
    const FieldConfig(
      label: "Ativo",
      fieldName: "ativo",
      icon: Icons.check_circle,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.boolean,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Gerar Chamado",
      fieldName: "gerChamado",
      icon: Icons.assignment,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.boolean,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Dia Vencimento",
      fieldName: "diaVencimento",
      icon: Icons.calendar_today,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descricao",
      fieldName: "descricao",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      isInForm: false,
    ),
    FieldConfig(
      label: "Regime Tributario",
      fieldName: "regimeTributario.id",
      displayFieldName: "regimeTributario.codigo",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadFormasPagamento(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    FieldConfig(
      label: "Setor Resposnsabilidade",
      fieldName: "setor.id",
      displayFieldName: "setor.descricao",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadSetores(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
      isRequired: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Status Envio",
      fieldName: "statusEnvio",
      icon: Icons.outgoing_mail,
      isInForm: false,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Protocolo",
      fieldName: "protocoloEnvio",
      icon: Icons.confirmation_number,
      isInForm: false,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Proximo Lembrete",
      fieldName: "proximoLembreteEm",
      icon: Icons.notifications_active,
      isInForm: false,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}

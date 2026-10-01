import 'package:flutter/material.dart';

import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';

// 🔥 Usa apenas FieldConfigWindows e FieldType (windows padrão)
import '../../../widgets/generic_grid_windows_screen.dart'
    show FieldConfigWindows, FieldType;

import 'empresa_model.dart';
import 'login_model.dart';
import 'parceiro_model.dart';
import 'setor_model.dart';

// =========================================================
// ENUMS
// =========================================================

enum StatusChamadoEnum {
  ABERTO(1, "Aberto"),
  EM_ANDAMENTO(2, "Em Andamento"),
  FECHADO(3, "Fechado"),
  CANCELADO(4, "Cancelado");

  final int value;
  final String label;
  const StatusChamadoEnum(this.value, this.label);

  static StatusChamadoEnum fromValue(int v) =>
      values.firstWhere((e) => e.value == v, orElse: () => ABERTO);

  // Fix card #451 (crash "Nao foi possivel carregar o sistema" ao clicar
  // em Visualizar): varios chamados existentes tem status nulo no banco
  // (visivel como celula em branco na coluna Status do grid). fromString
  // recebia String nao-nulo e chamava s.toUpperCase() direto -- com
  // status: null vindo do JSON dinamico, isso lancava NoSuchMethodError
  // nao capturado durante Chamado.fromJson, quebrando toda a arvore de
  // widgets do Flutter Web (sem error boundary).
  static StatusChamadoEnum fromString(String? s) {
    if (s == null || s.isEmpty) return ABERTO;
    return values.firstWhere(
      (e) => e.name.toUpperCase() == s.toUpperCase(),
      orElse: () => ABERTO,
    );
  }
}

enum PrioridadeChamadoEnum {
  BAIXA(1, "Baixa"),
  MEDIA(2, "Média"),
  ALTA(3, "Alta"),
  URGENTE(4, "Urgente");

  final int value;
  final String label;
  const PrioridadeChamadoEnum(this.value, this.label);

  static PrioridadeChamadoEnum fromValue(int v) =>
      values.firstWhere((e) => e.value == v, orElse: () => BAIXA);

  // Fix card #451: mesmo problema de StatusChamadoEnum.fromString --
  // chamados com prioridade nula no banco quebravam Chamado.fromJson.
  static PrioridadeChamadoEnum fromString(String? s) {
    if (s == null || s.isEmpty) return BAIXA;
    return values.firstWhere(
      (e) => e.name.toUpperCase() == s.toUpperCase(),
      orElse: () => BAIXA,
    );
  }
}

// =========================================================
// MODEL CHAMADO
// =========================================================

class Chamado {
  int? id;
  String titulo;
  String descricao;
  String? motivoFechamento;

  StatusChamadoEnum status;
  PrioridadeChamadoEnum prioridade;

  Empresa empresa;
  Login? usuarioAbertura;
  Login? usuarioFechamento;
  Parceiro? parceiro;
  Setor? setor;

  DateTime dataAbertura;
  DateTime? dataFechamento;

  Chamado({
    this.id,
    required this.titulo,
    required this.descricao,
    this.motivoFechamento,
    required this.status,
    required this.prioridade,
    required this.empresa,
    this.usuarioAbertura,
    this.usuarioFechamento,
    this.parceiro,
    this.setor,
    required this.dataAbertura,
    this.dataFechamento,
  });

  factory Chamado.fromJson(Map<String, dynamic> json) {
    return Chamado(
      id: json['id'],
      // Fix card #451: titulo/descricao sao tipados nao-nulos (String), mas
      // json e Map<String,dynamic> -- sem fallback, um chamado com esses
      // campos nulos no banco tambem quebraria Chamado.fromJson.
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      motivoFechamento: json['motivoFechamento'],
      status: StatusChamadoEnum.fromString(json['status']),
      prioridade: PrioridadeChamadoEnum.fromString(json['prioridade']),
      // Fix card #451: alguns chamados existentes nao tem empresa vinculada
      // (coluna Empresa em branco no grid) -- Empresa.fromJson(null)
      // quebraria com type error (espera Map<String,dynamic> nao-nulo).
      empresa: json['empresa'] != null ? Empresa.fromJson(json['empresa']) : Empresa(),
      usuarioAbertura: json['usuarioAbertura'] != null
          ? Login.fromJson(json['usuarioAbertura'])
          : null,
      usuarioFechamento: json['usuarioFechamento'] != null
          ? Login.fromJson(json['usuarioFechamento'])
          : null,
      parceiro:
          json['parceiro'] != null ? Parceiro.fromJson(json['parceiro']) : null,
      setor: json['setor'] != null ? Setor.fromJson(json['setor']) : null,
      dataAbertura: json['dataAbertura'] != null
          ? DateTime.parse(json['dataAbertura'])
          : DateTime.now(),
      dataFechamento: json['dataFechamento'] != null
          ? DateTime.parse(json['dataFechamento'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descricao': descricao,
      'motivoFechamento': motivoFechamento,
      'status': status.value,
      'prioridade': prioridade.value,
      'empresa': empresa.toJson(),
      'usuarioAbertura': usuarioAbertura?.toJson(),
      'usuarioFechamento': usuarioFechamento?.toJson(),
      'parceiro': parceiro?.toJson(),
      'setor': setor?.toJson(),
      'dataAbertura': dataAbertura.toIso8601String(),
      'dataFechamento': dataFechamento?.toIso8601String(),
    };
  }

  // =========================================================
  // DROPDOWNS PADRÃO WINDOWS
  // =========================================================

  static Future<List<Map<String, dynamic>>> loadSetores() async {
    final NetworkResponse res =
        await NetworkCaller().getRequest(ApiLinks.allSetores);

    if (res.isSuccess && res.body != null) {
      final List<dynamic> dados = res.body!["data"]["dados"] ?? [];
      return dados
          .map((item) => {
                'value': item['id'],
                'label': item['descricao'],
              })
          .toList();
    }
    return [];
  }

  static List<Map<String, dynamic>> getStatusDropdownItems() {
    return StatusChamadoEnum.values
        .map((e) => {'value': e.value, 'label': e.label})
        .toList();
  }

  static List<Map<String, dynamic>> getPrioridadeDropdownItems() {
    return PrioridadeChamadoEnum.values
        .map((e) => {'value': e.value, 'label': e.label})
        .toList();
  }

  // =========================================================
  // FIELDS PARA DETAIL SCREEN
  // =========================================================

  static List<FieldConfigWindows> fieldConfigsWindows() {
    return [
      const FieldConfigWindows(
        label: "Título",
        fieldName: "titulo",
        fieldType: FieldType.text,
        isRequired: true,
        icon: Icons.title,
      ),
      const FieldConfigWindows(
        label: "Descrição",
        fieldName: "descricao",
        fieldType: FieldType.multiline,
        maxLines: 4,
        icon: Icons.description,
      ),
      FieldConfigWindows(
        label: "Prioridade",
        fieldName: "prioridade",
        fieldType: FieldType.dropdown,
        dropdownOptions: getPrioridadeDropdownItems(),
        dropdownValueField: "value",
        dropdownDisplayField: "label",
        isRequired: true,
        icon: Icons.flag,
      ),
      FieldConfigWindows(
        label: "Parceiro",
        fieldName: "parceiro.id",
        displayFieldName: "parceiro.nome",
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () async => await _loadParceiros(),
        dropdownValueField: "value",
        dropdownDisplayField: "label",
        icon: Icons.person,
      ),
      FieldConfigWindows(
        label: "Setor",
        fieldName: "setor.id",
        displayFieldName: "setor.descricao",
        fieldType: FieldType.dropdown,
        dropdownFutureBuilder: () async => await loadSetores(),
        dropdownValueField: "value",
        dropdownDisplayField: "label",
        isRequired: true,
        icon: Icons.business,
      ),
      // Data abertura pré-preenchida com hoje
      FieldConfigWindows(
        label: "Data Abertura",
        fieldName: "dataAbertura",
        fieldType: FieldType.date,
        icon: Icons.calendar_today,
        defaultValue: DateTime.now().toIso8601String(),
      ),
    ];
  }

  static Future<List<Map<String, dynamic>>> _loadParceiros() async {
    final NetworkResponse res =
        await NetworkCaller().getRequest(ApiLinks.allParceiros);
    if (res.isSuccess && res.body != null) {
      final List<dynamic> dados = res.body!["data"]["dados"] ?? [];
      return dados.map((item) => {'value': item['id'], 'label': item['nome']}).toList();
    }
    return [];
  }

  // =========================================================
  // FIELDS PARA GRID WINDOWS
  // =========================================================

  static List<FieldConfigWindows> fieldConfigs = [
    const FieldConfigWindows(
      label: "Título",
      fieldName: "titulo",
      icon: Icons.title,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
      fieldType: FieldType.text,
    ),
    const FieldConfigWindows(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      fieldType: FieldType.text,
    ),
    FieldConfigWindows(
      label: "Status",
      fieldName: "status",
      icon: Icons.info,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: FieldType.dropdown,
      dropdownOptions: getStatusDropdownItems(),
      dropdownSelectedValue: 1, // ABERTO
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    FieldConfigWindows(
      label: "Prioridade",
      fieldName: "prioridade",
      icon: Icons.flag,
      isFilterable: true,
      isVisibleByDefault: true,
      fieldType: FieldType.dropdown,
      dropdownOptions: getPrioridadeDropdownItems(),
      dropdownSelectedValue: 1, // BAIXA
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    FieldConfigWindows(
      label: "Setor",
      fieldName: "setor.id",
      displayFieldName: "setor.descricao",
      icon: Icons.business,
      isInForm: true,
      isFilterable: true,
      fieldType: FieldType.dropdown,
      dropdownFutureBuilder: () async => await loadSetores(),
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
  ];
}

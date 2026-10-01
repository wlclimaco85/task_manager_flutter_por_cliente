import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';

import '../customization/generic_grid_card.dart';
import 'audit_model.dart'; // importe seu Audit aqui

class FormaPagamento {
  int? id;
  String nome;
  String descricao;
  final String status; // "Ativo" / "Inativo"
  Audit? audit; // 🔹 Agora usa o model de auditoria

  FormaPagamento({
    this.id,
    required this.nome,
    required this.descricao,
    required this.status,
    this.audit,
  });

  factory FormaPagamento.fromJson(Map<String, dynamic> json) {
    return FormaPagamento(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      status: parseStatus(json['status']),
      audit: json['audit'] != null ? Audit.fromJson(json['audit']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'status': statusToInt(status),
      'audit': audit?.toJson(),
    };
  }

  static String parseStatus(dynamic status) {
    if (status == null) return "Ativo";
    // Vindo do GET: pode ser int (0/1) ou Map {"id":0,"nome":"Ativo"}
    if (status is Map) {
      final id = status['id'];
      return id == 1 ? "Inativo" : "Ativo";
    }
    if (status is int) return status == 1 ? "Inativo" : "Ativo";
    if (status is String) return status == "1" ? "Inativo" : "Ativo";
    return "Ativo";
  }

  /// Converte label para inteiro que o backend espera (0=Ativo, 1=Inativo)
  static int statusToInt(String status) {
    return status == "Inativo" ? 1 : 0;
  }

  /// 🔹 Atalho para acessar a data de criação formatada
  String get createdAtFormatado {
    if (audit?.dataCreated == null) return '';
    return DateFormat('dd/MM/yyyy').format(audit!.dataCreated!);
  }

  /// Método estático para carregar todas as formas de pagamento
  static Future<List<Map<String, dynamic>>> loadFormasPagamento() async {
    // FP3: aplica TenantContext para filtrar por empresa/parceiro do usuário logado
    final NetworkResponse response = await NetworkCaller().getRequest(
      TenantContext.applyToUrl(ApiLinks.allFormasPagamento),
    );

    if (response.isSuccess && response.body != null) {
      final List<dynamic> data = response.body!['data']['dados'] ?? [];
      return data
          .map(
            (item) => {
              'value': item['id'], // id da forma de pagamento
              'label': item['nome'].toString(), // nome da forma
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
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: true,
    ),
    const FieldConfig(
      label: "Nome",
      fieldName: "nome",
      icon: Icons.payment,
      isInForm: true,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Descrição",
      fieldName: "descricao",
      icon: Icons.description,
      isInForm: true,
      isVisibleByDefault: true,
      isFixed: false,
    ),
    const FieldConfig(
      label: "Status",
      fieldName: "status",
      icon: Icons.check_circle,
      isFilterable: true,
      isVisibleByDefault: true,
      isFixed: false,
      fieldType: FieldType.dropdown,
      dropdownOptions: [
        {'value': 'Ativo', 'label': 'Ativo'},
        {'value': 'Inativo', 'label': 'Inativo'},
      ],
      dropdownValueField: 'value',
      dropdownDisplayField: 'label',
    ),
    const FieldConfig(
      label: "Data Criação",
      fieldName: "audit.dataCreated", // 🔹 ajustado para usar audit
      icon: Icons.calendar_today,
      isVisibleByDefault: true,
      isFixed: false,
    ),
  ];
}

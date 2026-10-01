import 'package:flutter/material.dart';

class AlvaraModel {
  int? id;
  String descricao;
  String? numero;
  String? dataEmissao;
  String? dataVencimento;
  String? orgaoEmissor;
  String? tipoAlvara;
  String? status;
  String? observacao;
  Map<String, dynamic>? empresa;
  Map<String, dynamic>? parceiro;
  Map<String, dynamic>? file;

  AlvaraModel({
    this.id,
    required this.descricao,
    this.numero,
    this.dataEmissao,
    this.dataVencimento,
    this.orgaoEmissor,
    this.tipoAlvara,
    this.status = 'ATIVO',
    this.observacao,
    this.empresa,
    this.parceiro,
    this.file,
  });

  factory AlvaraModel.fromJson(Map<String, dynamic> json) {
    return AlvaraModel(
      id: json['id'] as int?,
      descricao: json['descricao']?.toString() ?? '',
      numero: json['numero']?.toString(),
      dataEmissao: json['dataEmissao']?.toString() ?? json['data_emissao']?.toString(),
      dataVencimento: json['dataVencimento']?.toString() ?? json['data_vencimento']?.toString(),
      orgaoEmissor: json['orgaoEmissor']?.toString() ?? json['orgao_emissor']?.toString(),
      tipoAlvara: json['tipoAlvara']?.toString() ?? json['tipo_alvara']?.toString(),
      status: json['status']?.toString() ?? 'ATIVO',
      observacao: json['observacao']?.toString(),
      empresa: json['empresa'] != null ? Map<String, dynamic>.from(json['empresa']) : null,
      parceiro: json['parceiro'] != null ? Map<String, dynamic>.from(json['parceiro']) : null,
      file: json['file'] != null ? Map<String, dynamic>.from(json['file']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'descricao': descricao,
    if (numero != null) 'numero': numero,
    if (dataEmissao != null) 'dataEmissao': dataEmissao,
    if (dataVencimento != null) 'dataVencimento': dataVencimento,
    if (orgaoEmissor != null) 'orgaoEmissor': orgaoEmissor,
    if (tipoAlvara != null) 'tipoAlvara': tipoAlvara,
    'status': status ?? 'ATIVO',
    if (observacao != null) 'observacao': observacao,
    if (empresa != null) 'empresa': empresa,
    if (parceiro != null) 'parceiro': parceiro,
    if (file != null) 'file': file,
  };

  /// Retorna cor de acordo com o status/vencimento
  Color get statusColor {
    if (status == 'VENCIDO' || status == 'CANCELADO') return Colors.red.shade700;
    if (status == 'EM_RENOVACAO') return Colors.orange.shade700;
    if (dataVencimento != null) {
      try {
        final venc = DateTime.parse(dataVencimento!);
        final diff = venc.difference(DateTime.now()).inDays;
        if (diff <= 0) return Colors.red.shade700;
        if (diff <= 15) return Colors.orange.shade700;
        if (diff <= 30) return Colors.amber.shade700;
      } catch (_) {}
    }
    return Colors.green.shade700;
  }

  String get statusLabel {
    return switch (status ?? 'ATIVO') {
      'ATIVO'        => 'Ativo',
      'VENCIDO'      => 'Vencido',
      'EM_RENOVACAO' => 'Em Renovação',
      'CANCELADO'    => 'Cancelado',
      _              => status ?? 'Ativo',
    };
  }

  bool get temPdf => file != null && (file!['id'] != null);
}

import 'package:flutter/material.dart';
import '../../utils/grid_colors.dart';

/// Modelo otimizado para exibição em listas de NFe.
/// Contém apenas os campos necessários para renderização de grid.
/// Para detalhes completos, consultar [NfeModel] (entidade completa).
class NfeListItemModel {
  final int id;
  final String numero;
  final String serie;
  final String status;
  final String dataEmissao; // ISO 8601: YYYY-MM-DDTHH:mm:ss
  final double valor;
  final String destinatario; // Nome do cliente
  final String? chave; // Chave de acesso (11 dígitos)
  final String? qrCode; // QR code ou URL para download

  NfeListItemModel({
    required this.id,
    required this.numero,
    required this.serie,
    required this.status,
    required this.dataEmissao,
    required this.valor,
    required this.destinatario,
    this.chave,
    this.qrCode,
  });

  /// Factory para converter de JSON (resposta da API)
  factory NfeListItemModel.fromJson(Map<String, dynamic> json) {
    return NfeListItemModel(
      id: json['id'] as int? ?? 0,
      numero: json['numero']?.toString() ?? '',
      serie: json['serie']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PENDENTE',
      dataEmissao: json['dataEmissao']?.toString() ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
      destinatario: json['destinatario']?.toString() ?? '',
      chave: json['chave']?.toString(),
      qrCode: json['qrCode']?.toString(),
    );
  }

  /// Converte modelo para JSON (para envio à API)
  Map<String, dynamic> toJson() => {
    'id': id,
    'numero': numero,
    'serie': serie,
    'status': status,
    'dataEmissao': dataEmissao,
    'valor': valor,
    'destinatario': destinatario,
    if (chave != null) 'chave': chave,
    if (qrCode != null) 'qrCode': qrCode,
  };

  /// Retorna cor correspondente ao status da NFe
  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'AUTORIZADA':
        return GridColors.success;
      case 'CANCELADA':
        return GridColors.error;
      case 'REJEITADA':
        return const Color(0xFFE65100); // Orange-800
      case 'PENDENTE':
      case 'RASCUNHO':
        return const Color(0xFFF9A825); // Amber-600
      default:
        return const Color(0xFF757575); // Gray-600
    }
  }

  /// Retorna rótulo legível do status
  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'AUTORIZADA':
        return 'Autorizada';
      case 'CANCELADA':
        return 'Cancelada';
      case 'REJEITADA':
        return 'Rejeitada';
      case 'PENDENTE':
        return 'Pendente';
      case 'RASCUNHO':
        return 'Rascunho';
      default:
        return status;
    }
  }

  /// Formata valor em reais
  String get valorFormatado {
    return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  /// Extrai dia/mês/ano da data ISO
  String get dataFormatada {
    if (dataEmissao.isEmpty) return '';
    try {
      final dt = DateTime.parse(dataEmissao);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (e) {
      return dataEmissao;
    }
  }

  /// Trunca nome do destinatário para evitar overflow
  String get destinatarioTruncado {
    const maxLength = 25;
    if (destinatario.length <= maxLength) {
      return destinatario;
    }
    return '${destinatario.substring(0, maxLength)}...';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NfeListItemModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          numero == other.numero &&
          serie == other.serie &&
          status == other.status &&
          valor == other.valor;

  @override
  int get hashCode => id.hashCode ^ numero.hashCode ^ serie.hashCode;

  /// Cópia do modelo com campos sobrescritos (imutabilidade)
  NfeListItemModel copyWith({
    int? id,
    String? numero,
    String? serie,
    String? status,
    String? dataEmissao,
    double? valor,
    String? destinatario,
    String? chave,
    String? qrCode,
  }) {
    return NfeListItemModel(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      serie: serie ?? this.serie,
      status: status ?? this.status,
      dataEmissao: dataEmissao ?? this.dataEmissao,
      valor: valor ?? this.valor,
      destinatario: destinatario ?? this.destinatario,
      chave: chave ?? this.chave,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}

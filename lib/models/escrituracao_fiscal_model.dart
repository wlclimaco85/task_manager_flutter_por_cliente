class EscrituracaoFiscal {
  int? id;
  int empresaId;
  String periodo;
  String tipo;
  int? totalDocumentos;
  double? valorTotal;
  double? valorBaseIcms;
  double? valorIcms;
  double? valorBaseIbs;
  double? valorIbs;
  double? valorBaseCbs;
  double? valorCbs;
  String status;
  DateTime? createdAt;
  DateTime? updatedAt;

  EscrituracaoFiscal({
    this.id,
    required this.empresaId,
    required this.periodo,
    required this.tipo,
    this.totalDocumentos,
    this.valorTotal,
    this.valorBaseIcms,
    this.valorIcms,
    this.valorBaseIbs,
    this.valorIbs,
    this.valorBaseCbs,
    this.valorCbs,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory EscrituracaoFiscal.fromJson(Map<String, dynamic> json) {
    return EscrituracaoFiscal(
      id: json['id'],
      empresaId: json['empresaId'] ?? json['empresa_id'] ?? 0,
      periodo: json['periodo']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      totalDocumentos: json['totalDocumentos'] ?? json['total_documentos'],
      valorTotal: (json['valorTotal'] ?? json['valor_total'] as num?)?.toDouble(),
      valorBaseIcms:
          (json['valorBaseIcms'] ?? json['valor_base_icms'] as num?)?.toDouble(),
      valorIcms: (json['valorIcms'] ?? json['valor_icms'] as num?)?.toDouble(),
      valorBaseIbs:
          (json['valorBaseIbs'] ?? json['valor_base_ibs'] as num?)?.toDouble(),
      valorIbs: (json['valorIbs'] ?? json['valor_ibs'] as num?)?.toDouble(),
      valorBaseCbs:
          (json['valorBaseCbs'] ?? json['valor_base_cbs'] as num?)?.toDouble(),
      valorCbs: (json['valorCbs'] ?? json['valor_cbs'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? '',
      createdAt: _parseDateTime(json['createdAt'] ?? json['created_at']),
      updatedAt: _parseDateTime(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'empresaId': empresaId,
        'periodo': periodo,
        'tipo': tipo,
        'totalDocumentos': totalDocumentos,
        'valorTotal': valorTotal,
        'valorBaseIcms': valorBaseIcms,
        'valorIcms': valorIcms,
        'valorBaseIbs': valorBaseIbs,
        'valorIbs': valorIbs,
        'valorBaseCbs': valorBaseCbs,
        'valorCbs': valorCbs,
        'status': status,
      };

  String get statusLabel {
    switch (status) {
      case 'RASCUNHO':
        return 'Rascunho';
      case 'CONFERIDA':
        return 'Conferida';
      case 'FECHADA':
        return 'Fechada';
      default:
        return status;
    }
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

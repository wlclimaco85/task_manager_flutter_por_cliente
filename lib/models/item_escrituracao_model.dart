class ItemEscrituracao {
  int? id;
  int escrituracaoId;
  int? nfeId;
  String? chaveAcesso;
  String? cfop;
  String? ncm;
  double? valor;
  double? baseIcms;
  double? valorIcms;
  double? baseIbs;
  double? valorIbs;
  double? baseCbs;
  double? valorCbs;
  String status;
  String? inconsistencia;

  ItemEscrituracao({
    this.id,
    required this.escrituracaoId,
    this.nfeId,
    this.chaveAcesso,
    this.cfop,
    this.ncm,
    this.valor,
    this.baseIcms,
    this.valorIcms,
    this.baseIbs,
    this.valorIbs,
    this.baseCbs,
    this.valorCbs,
    required this.status,
    this.inconsistencia,
  });

  factory ItemEscrituracao.fromJson(Map<String, dynamic> json) {
    return ItemEscrituracao(
      id: json['id'],
      escrituracaoId: json['escrituracaoId'] ?? json['escrituracao_id'] ?? 0,
      nfeId: json['nfeId'] ?? json['nfe_id'],
      chaveAcesso: json['chaveAcesso'] ?? json['chave_acesso'],
      cfop: json['cfop'],
      ncm: json['ncm'],
      valor: (json['valor'] as num?)?.toDouble(),
      baseIcms: (json['baseIcms'] ?? json['base_icms'] as num?)?.toDouble(),
      valorIcms: (json['valorIcms'] ?? json['valor_icms'] as num?)?.toDouble(),
      baseIbs: (json['baseIbs'] ?? json['base_ibs'] as num?)?.toDouble(),
      valorIbs: (json['valorIbs'] ?? json['valor_ibs'] as num?)?.toDouble(),
      baseCbs: (json['baseCbs'] ?? json['base_cbs'] as num?)?.toDouble(),
      valorCbs: (json['valorCbs'] ?? json['valor_cbs'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? '',
      inconsistencia: json['inconsistencia'],
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'escrituracaoId': escrituracaoId,
        'nfeId': nfeId,
        'chaveAcesso': chaveAcesso,
        'cfop': cfop,
        'ncm': ncm,
        'valor': valor,
        'baseIcms': baseIcms,
        'valorIcms': valorIcms,
        'baseIbs': baseIbs,
        'valorIbs': valorIbs,
        'baseCbs': baseCbs,
        'valorCbs': valorCbs,
        'status': status,
        'inconsistencia': inconsistencia,
      };

  String get statusLabel {
    switch (status) {
      case 'OK':
        return 'OK';
      case 'INCONSISTENTE':
        return 'Inconsistente';
      default:
        return status;
    }
  }
}

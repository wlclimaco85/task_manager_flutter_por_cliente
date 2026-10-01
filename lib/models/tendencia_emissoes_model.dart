class TendenciaEmissoesModel {
  final String mes; // "2026-01" (YYYY-MM)
  final int quantidade; // total de NF-e/NFS-e emitidas no mês

  TendenciaEmissoesModel({
    required this.mes,
    required this.quantidade,
  });

  factory TendenciaEmissoesModel.fromJson(Map<String, dynamic> json) {
    return TendenciaEmissoesModel(
      mes: json['mes'] as String? ?? '',
      quantidade: (json['quantidade'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'mes': mes,
    'quantidade': quantidade,
  };
}

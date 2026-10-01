class TendenciaHorasExtrasModel {
  final String mes; // "2026-01" (YYYY-MM)
  final double valor; // horas em formato decimal (ex: 10.5)

  TendenciaHorasExtrasModel({
    required this.mes,
    required this.valor,
  });

  factory TendenciaHorasExtrasModel.fromJson(Map<String, dynamic> json) {
    return TendenciaHorasExtrasModel(
      mes: json['mes'] as String? ?? '',
      valor: (json['valor'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'mes': mes,
    'valor': valor,
  };
}

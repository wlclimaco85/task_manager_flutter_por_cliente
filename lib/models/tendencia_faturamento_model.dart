// lib/models/tendencia_faturamento_model.dart
// Espelha TendenciaFaturamentoDTO do backend

class TendenciaFaturamentoModel {
  final String mes;      // "2026-01", "2026-02", etc.
  final double valor;    // Valor faturado no mês

  const TendenciaFaturamentoModel({
    required this.mes,
    required this.valor,
  });

  factory TendenciaFaturamentoModel.fromJson(Map<String, dynamic> json) {
    return TendenciaFaturamentoModel(
      mes: json['mes']?.toString() ?? '',
      valor: _toDouble(json['valor']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

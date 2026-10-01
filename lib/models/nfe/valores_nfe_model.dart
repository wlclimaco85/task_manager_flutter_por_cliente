/// Modelo que representa os valores/totalizações de uma NFe
class ValoresNfeModel {
  final double subtotal;
  final double totalIcms;
  final double totalPis;
  final double totalCofins;
  final double desconto;
  final double total;

  const ValoresNfeModel({
    required this.subtotal,
    required this.totalIcms,
    required this.totalPis,
    required this.totalCofins,
    required this.desconto,
    required this.total,
  });

  /// Cria instância a partir de JSON
  factory ValoresNfeModel.fromJson(Map<String, dynamic> json) {
    return ValoresNfeModel(
      subtotal: _toDouble(json['subtotal']),
      totalIcms: _toDouble(json['totalIcms']),
      totalPis: _toDouble(json['totalPis']),
      totalCofins: _toDouble(json['totalCofins']),
      desconto: _toDouble(json['desconto']),
      total: _toDouble(json['total']),
    );
  }

  /// Converte para JSON
  Map<String, dynamic> toJson() => {
    'subtotal': subtotal,
    'totalIcms': totalIcms,
    'totalPis': totalPis,
    'totalCofins': totalCofins,
    'desconto': desconto,
    'total': total,
  };

  /// Calcula total de impostos (ICMS + PIS + COFINS)
  double get totalImpostos => totalIcms + totalPis + totalCofins;

  /// Calcula alíquota efetiva de impostos (%)
  double get aliquotaEfetiva {
    if (subtotal == 0) return 0;
    return (totalImpostos / subtotal) * 100;
  }

  /// Helper para converter valor para double com segurança
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

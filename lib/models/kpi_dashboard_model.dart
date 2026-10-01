// lib/models/kpi_dashboard_model.dart
//
// Modelo Dart espelhando KpiDashboardDTO/DashboardAreaResponseDTO (backend, Fase 171).
// fromJson defensivo: aceita null/num/string e nunca lança exceção em campo ausente.

class KpiDashboardModel {
  final String chave;
  final String label;
  final double valor;
  final String? unidade;
  final String? tendencia;
  final String? drillDownRota;

  const KpiDashboardModel({
    required this.chave,
    required this.label,
    required this.valor,
    this.unidade,
    this.tendencia,
    this.drillDownRota,
  });

  factory KpiDashboardModel.fromJson(Map<String, dynamic> json) {
    return KpiDashboardModel(
      chave: json['chave']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      valor: _toDouble(json['valor']),
      unidade: json['unidade']?.toString(),
      tendencia: json['tendencia']?.toString(),
      drillDownRota: json['drillDownRota']?.toString(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

/// Espelha DashboardAreaResponseDTO (backend) — resposta completa de
/// GET /api/dashboard/{area}/kpis.
class DashboardAreaResponseModel {
  final String area;
  final DateTime? periodoInicio;
  final DateTime? periodoFim;
  final List<KpiDashboardModel> kpis;

  const DashboardAreaResponseModel({
    required this.area,
    this.periodoInicio,
    this.periodoFim,
    this.kpis = const [],
  });

  factory DashboardAreaResponseModel.fromJson(Map<String, dynamic> json) {
    final kpisJson = json['kpis'];
    return DashboardAreaResponseModel(
      area: json['area']?.toString() ?? '',
      periodoInicio: _parseDate(json['periodoInicio']),
      periodoFim: _parseDate(json['periodoFim']),
      kpis: kpisJson is List
          ? kpisJson
              .whereType<Map>()
              .map((e) => KpiDashboardModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}

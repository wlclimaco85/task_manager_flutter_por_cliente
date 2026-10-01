import 'dart:convert';
import '../models/dashboard_comercial_mercadorias_model.dart';
import '../models/kpi_dashboard_model.dart';
import '../models/tendencia_faturamento_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

/// Caller do dashboard de área Comercial (Fase 171 — fundação).
class DashboardComercialCaller {
  Future<DashboardComercialMercadoriasModel?> fetchMercadorias({
    int? empresaId,
    int? parceiroId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      var url = ApiLinks.dashboardComercialMercadorias;
      final params = <String>[];
      if (empresaId != null) params.add('empresaId=$empresaId');
      if (parceiroId != null) params.add('parceiroId=$parceiroId');
      if (dataInicio != null) {
        params.add('dataInicio=${dataInicio.toIso8601String().split('T').first}');
      }
      if (dataFim != null) {
        params.add('dataFim=${dataFim.toIso8601String().split('T').first}');
      }
      if (params.isNotEmpty) url = '$url?${params.join('&')}';

      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        if (body is Map) {
          return DashboardComercialMercadoriasModel.fromJson(
              Map<String, dynamic>.from(body));
        }
      }
    } catch (_) {}
    return null;
  }

  Future<DashboardAreaResponseModel?> fetchKpis({
    DateTime? periodoInicio,
    DateTime? periodoFim,
  }) async {
    try {
      var url = ApiLinks.dashboardComercialKpis;
      final params = <String>[];
      if (periodoInicio != null) {
        params.add('periodoInicio=${periodoInicio.toIso8601String().split('T').first}');
      }
      if (periodoFim != null) {
        params.add('periodoFim=${periodoFim.toIso8601String().split('T').first}');
      }
      if (params.isNotEmpty) url = '$url?${params.join('&')}';

      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        if (body is Map) {
          return DashboardAreaResponseModel.fromJson(Map<String, dynamic>.from(body));
        }
      }
    } catch (_) {
      // Fallback silencioso — mesmo padrão já usado em SaudeDiariaCaller.
    }
    return null;
  }

  /// Retorna tendência de faturamento dos últimos 6 meses.
  Future<List<TendenciaFaturamentoModel>?> fetchTendenciaFaturamento() async {
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/dashboard/comercial/tendencia-faturamento');
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        if (body is List) {
          return body
              .whereType<Map>()
              .map((e) => TendenciaFaturamentoModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {
      // Fallback silencioso
    }
    return null;
  }
}

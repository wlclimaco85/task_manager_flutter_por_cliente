import 'dart:convert';
import '../models/kpi_dashboard_model.dart';
import '../models/tendencia_emissoes_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

/// Caller do dashboard de área Fiscal (Fase 171 — fundação).
class DashboardFiscalCaller {
  Future<DashboardAreaResponseModel?> fetchKpis({
    DateTime? periodoInicio,
    DateTime? periodoFim,
  }) async {
    try {
      var url = ApiLinks.dashboardFiscalKpis;
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

  /// Retorna tendência de emissões dos últimos 6 meses.
  Future<List<TendenciaEmissoesModel>?> fetchEmissoes() async {
    try {
      final resp = await TenantContext.get('${ApiLinks.baseUrl}/dashboard/fiscal/emissoes');
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        final body = jsonDecode(utf8.decode(resp.bodyBytes));
        if (body is List) {
          return body
              .whereType<Map>()
              .map((e) => TendenciaEmissoesModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      }
    } catch (_) {
      // Fallback silencioso
    }
    return null;
  }
}

import 'dart:convert';
import '../models/kpi_dashboard_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

/// Caller do dashboard de área Financeiro (Fase 171 — fundação).
/// Distinto de DashboardFinanceiroCaller (módulo financeiro legado já
/// maduro) — consome a rota nova /api/dashboard/financeiro-area/kpis.
class DashboardFinanceiroAreaCaller {
  Future<DashboardAreaResponseModel?> fetchKpis({
    DateTime? periodoInicio,
    DateTime? periodoFim,
  }) async {
    try {
      var url = ApiLinks.dashboardFinanceiroAreaKpis;
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
}

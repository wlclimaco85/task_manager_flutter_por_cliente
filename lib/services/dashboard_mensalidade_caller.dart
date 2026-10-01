import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/mes_cobranca_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class DashboardMensalidadeCaller {
  static final String _base = '${ApiLinks.baseUrl}/api/dashboard/mensalidade';
  static final String _financeiroBase = '${ApiLinks.baseUrl}/api/dashboard/financeiro';

  Future<Map<String, dynamic>?> fetchKpis({String? mesInicio, String? mesFim}) async {
    try {
      final params = <String>[];
      if (mesInicio != null) params.add('mesInicio=$mesInicio');
      if (mesFim != null) params.add('mesFim=$mesFim');
      final url = '$_base/kpis${params.isNotEmpty ? '?${params.join('&')}' : ''}';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[DashboardMensalidadeCaller] fetchKpis: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> fetchSerieMensal({int meses = 12}) async {
    try {
      final url = '$_base/serie-mensal?meses=$meses';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final list = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('[DashboardMensalidadeCaller] fetchSerieMensal: $e');
    }
    return null;
  }

  Future<Uint8List?> baixarPdf({String? mesInicio, String? mesFim}) async {
    try {
      final params = <String>[];
      if (mesInicio != null) params.add('mesInicio=$mesInicio');
      if (mesFim != null) params.add('mesFim=$mesFim');
      final url = '$_base/relatorio-pdf${params.isNotEmpty ? '?${params.join('&')}' : ''}';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) return resp.bodyBytes;
    } catch (e) {
      debugPrint('[DashboardMensalidadeCaller] baixarPdf: $e');
    }
    return null;
  }

  /// Fetch tendência de 6 meses de cobrança.
  Future<List<MesCobranca>> fetchTendencia6Meses() async {
    try {
      final url = '$_financeiroBase/mensalidade-dashboard/tendencia-6meses';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(resp.bodyBytes)) as List;
        return jsonData.map((item) => MesCobranca.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('[DashboardMensalidadeCaller] fetchTendencia6Meses: $e');
    }
    return [];
  }
}

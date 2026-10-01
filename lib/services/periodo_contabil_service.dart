import 'dart:convert';
import '../models/auth_utility.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class PeriodoContabilService {

  Future<List<Map<String, dynamic>>> listarPeriodos(int empresaId) async {
    try {
      final r = await TenantContext.get(ApiLinks.allPeriodosContabeis(empresaId.toString()));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is List ? b : (b['data'] is List ? b['data'] : []);
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> validarFechamento(int empresaId, String periodo) async {
    try {
      final r = await TenantContext.get(ApiLinks.validarFechamentoUrl(empresaId.toString(), periodo));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> fecharPeriodo(int empresaId, String periodo) async {
    try {
      final userId = AuthUtility.userInfo?.login?.id?.toString();
      final r = await TenantContext.post(
        ApiLinks.fecharPeriodoUrl(empresaId.toString(), periodo, userId != null ? int.tryParse(userId) : null), {});
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> analisarFechamento(int empresaId, String periodo) async {
    try {
      final r = await TenantContext.get(ApiLinks.analisarFechamentoUrl(empresaId.toString(), periodo));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }
}

import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class AiAnaliseService {

  Future<Map<String, dynamic>?> analisarDre(int empresaId, String periodo) async {
    try {
      final r = await TenantContext.get(ApiLinks.analisarDreUrl(empresaId.toString(), periodo));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>?> anomaliasFiscais(int empresaId, {String? periodo}) async {
    try {
      final r = await TenantContext.get(ApiLinks.anomaliasFiscaisUrl(empresaId.toString(), periodo));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is List ? b : (b['data'] is List ? b['data'] : []);
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> preverObrigacoes(int empresaId) async {
    try {
      final r = await TenantContext.get(ApiLinks.preverObrigacoesUrl(empresaId.toString()));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> perguntar(int empresaId, String pergunta) async {
    try {
      final r = await TenantContext.get(ApiLinks.perguntarAiUrl(empresaId.toString(), pergunta));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }
}

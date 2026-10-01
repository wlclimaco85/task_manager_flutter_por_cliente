import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class ContaContabilService {
  Future<List<Map<String, dynamic>>> listar(int empresaId, {bool? ativas}) async {
    try {
      final url = ativas == true
          ? ApiLinks.contasContabeisAtivas(empresaId.toString())
          : '${ApiLinks.allContasContabeis}?empresaId=$empresaId';
      final r = await TenantContext.get(url);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is List ? b : (b['data'] is List ? b['data'] : []);
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> criar(Map<String, dynamic> body) async {
    try {
      final r = await TenantContext.post(ApiLinks.createContaContabil, body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> atualizar(String id, Map<String, dynamic> body) async {
    try {
      final r = await TenantContext.put(ApiLinks.updateContaContabil(id), body);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deletar(String id) async {
    try {
      final r = await TenantContext.delete(ApiLinks.deleteContaContabil(id));
      return r.statusCode == 204 || r.statusCode == 200;
    } catch (_) {}
    return false;
  }
}

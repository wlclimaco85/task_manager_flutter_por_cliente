import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class LancamentoContabilService {
  Future<List<Map<String, dynamic>>> listar(int empresaId, String periodo) async {
    try {
      final r = await TenantContext.get(ApiLinks.allLancamentosContabeis(empresaId.toString(), periodo));
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
      final r = await TenantContext.post(ApiLinks.createLancamentoContabil, body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> atualizar(String id, Map<String, dynamic> body) async {
    try {
      final r = await TenantContext.put(ApiLinks.updateLancamentoContabil(id), body);
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> deletar(String id) async {
    try {
      final r = await TenantContext.delete(ApiLinks.deleteLancamentoContabil(id));
      return r.statusCode == 204 || r.statusCode == 200;
    } catch (_) {}
    return false;
  }

  Future<List<Map<String, dynamic>>?> autoGerar(int empresaId, String periodo) async {
    try {
      final r = await TenantContext.post(ApiLinks.autoGerarLancamentos(empresaId.toString(), periodo), {});
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        final data = b is List ? b : (b['data'] is List ? b['data'] : []);
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>?> balancete(int empresaId, String dataInicio, String dataFim) async {
    try {
      final r = await TenantContext.get(ApiLinks.balanceteUrl(empresaId.toString(), dataInicio, dataFim));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is List ? b : (b['data'] is List ? b['data'] : []);
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>?> balanco(int empresaId, String data) async {
    try {
      final r = await TenantContext.get(ApiLinks.balancoUrl(empresaId.toString(), data));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is List ? b : (b['data'] is List ? b['data'] : []);
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> analisarVariacao(int empresaId, String periodo, String? comparacao) async {
    try {
      final r = await TenantContext.get(ApiLinks.analisarVariacaoUrl(empresaId.toString(), periodo, comparacao));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        return b is Map ? Map<String, dynamic>.from(b) : null;
      }
    } catch (_) {}
    return null;
  }
}

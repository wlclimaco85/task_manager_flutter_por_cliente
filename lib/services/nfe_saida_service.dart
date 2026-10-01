import 'dart:convert';
import '../models/nfe/nfe_item_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NfeSaidaService {

  Future<List<Map<String, dynamic>>> carregarTiposOperacao() async {
    try {
      final r = await TenantContext.get('${ApiLinks.allNfeTipoOperacao}?tamanho=200&ativo=true');
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is Map ? (b['data'] is Map ? b['data']['dados'] : b['data']) : b;
        return (data as List? ?? []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  Future<Map<String, dynamic>?> criarNfe(Map<String, dynamic> body) async {
    try {
      final r = await TenantContext.post(ApiLinks.createNfe, body);
      if (r.statusCode == 200 || r.statusCode == 201) {
        final b = jsonDecode(r.body);
        if (b is Map) {
          final data = b['data'] is Map ? b['data'] : b;
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Persiste um item de NFe já existente ([nfeId]) via `POST /api/nfe_item`.
  ///
  /// Necessário porque `criarNfe` só cria o cabeçalho da NFe — o endpoint
  /// de criação (`NfeCriacaoDTO`) não aceita itens. Cada item precisa ser
  /// enviado individualmente após a criação do cabeçalho.
  Future<bool> criarItem(int nfeId, NfeItemModel item) async {
    try {
      final body = <String, dynamic>{
        'nfeId': nfeId,
        'cProd': item.codigoProduto,
        'xProd': item.descricao,
        'ncm': item.ncm,
        'cfop': item.cfop,
        'uCom': item.unidade,
        'qCom': item.quantidade,
        'vUnCom': item.precoUnitario,
        'vProd': item.precoTotal,
        'cstIcms': item.cstIcms,
        'aliqIcms': item.aliqIcms,
      };
      final r = await TenantContext.post('${ApiLinks.baseUrl}/api/nfe_item', body);
      return r.statusCode == 200 || r.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> buscarNfe(String id) async {
    try {
      final r = await TenantContext.get(ApiLinks.nfeById(id));
      if (r.statusCode == 200) {
        final b = jsonDecode(r.body);
        final data = b is Map ? (b['data'] is Map ? b['data'] : b) : null;
        return data != null ? Map<String, dynamic>.from(data) : null;
      }
    } catch (_) {}
    return null;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/escrituracao_fiscal_model.dart';
import '../models/item_escrituracao_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class EscrituracaoFiscalService {
  Future<List<EscrituracaoFiscal>> listar({required int empresaId}) async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(ApiLinks.escrituracaoFiscalListar(empresaId)),
      ),
      headers: TenantContext.jsonHeaders,
    );
    return _parseList(response);
  }

  Future<EscrituracaoFiscal> detalhe(int id) async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(ApiLinks.escrituracaoFiscalDetalhe(id)),
      ),
      headers: TenantContext.jsonHeaders,
    );
    return _parseSingle(response);
  }

  Future<List<ItemEscrituracao>> itens(int escrituracaoId) async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(ApiLinks.escrituracaoFiscalItens(escrituracaoId)),
      ),
      headers: TenantContext.jsonHeaders,
    );
    return _parseItemList(response);
  }

  Future<EscrituracaoFiscal> gerar({
    required int empresaId,
    required String periodo,
    required String tipo,
  }) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.escrituracaoFiscalGerar)),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'empresaId': empresaId,
        'periodo': periodo,
        'tipo': tipo,
      }),
    );
    return _parseSingle(response);
  }

  Future<EscrituracaoFiscal> conferir(int id) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.escrituracaoFiscalConferir(id))),
      headers: TenantContext.jsonHeaders,
    );
    return _parseSingle(response);
  }

  Future<EscrituracaoFiscal> fechar(int id) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.escrituracaoFiscalFechar(id))),
      headers: TenantContext.jsonHeaders,
    );
    return _parseSingle(response);
  }

  List<EscrituracaoFiscal> _parseList(http.Response response) {
    final body = _decode(response.bodyBytes);
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => EscrituracaoFiscal.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw EscrituracaoFiscalException('Erro ao listar escriturações (${response.statusCode}).');
  }

  EscrituracaoFiscal _parseSingle(http.Response response) {
    final body = _decode(response.bodyBytes);
    if (body is Map<String, dynamic>) {
      return EscrituracaoFiscal.fromJson(body);
    }
    if (body is Map) {
      return EscrituracaoFiscal.fromJson(Map<String, dynamic>.from(body));
    }
    throw EscrituracaoFiscalException('Erro ao processar escrituração (${response.statusCode}).');
  }

  List<ItemEscrituracao> _parseItemList(http.Response response) {
    final body = _decode(response.bodyBytes);
    if (body is List) {
      return body
          .whereType<Map>()
          .map((e) => ItemEscrituracao.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw EscrituracaoFiscalException('Erro ao listar itens (${response.statusCode}).');
  }

  dynamic _decode(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(bodyBytes));
  }
}

class EscrituracaoFiscalException implements Exception {
  final String message;
  const EscrituracaoFiscalException(this.message);
  @override
  String toString() => message;
}

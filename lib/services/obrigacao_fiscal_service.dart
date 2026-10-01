import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/obrigacao_fiscal_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class ObrigacaoFiscalService {
  Future<ObrigacaoFiscal> registrarEnvio({
    required int obrigacaoId,
    String canalEnvio = 'EMAIL',
    String? mensagemEnvio,
    DateTime? proximoLembreteEm,
  }) async {
    final response = await http.post(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.enviarObrigacaoFiscal(obrigacaoId.toString()),
        ),
      ),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'canalEnvio': canalEnvio,
        if (mensagemEnvio != null) 'mensagemEnvio': mensagemEnvio,
        if (proximoLembreteEm != null)
          'proximoLembreteEm': proximoLembreteEm.toIso8601String(),
      }),
    );

    return _parseObrigacao(response, 'Erro ao registrar envio da obrigacao.');
  }

  Future<ObrigacaoFiscal> atualizarStatusEnvio({
    required int obrigacaoId,
    required String statusEnvio,
    String? protocoloEnvio,
    String? mensagemEnvio,
    DateTime? proximoLembreteEm,
  }) async {
    final response = await http.post(
      Uri.parse(
        TenantContext.applyToUrl(
          ApiLinks.atualizarStatusEnvioObrigacaoFiscal(obrigacaoId.toString()),
        ),
      ),
      headers: TenantContext.jsonHeaders,
      body: jsonEncode({
        'statusEnvio': statusEnvio,
        if (protocoloEnvio != null) 'protocoloEnvio': protocoloEnvio,
        if (mensagemEnvio != null) 'mensagemEnvio': mensagemEnvio,
        if (proximoLembreteEm != null)
          'proximoLembreteEm': proximoLembreteEm.toIso8601String(),
      }),
    );

    return _parseObrigacao(response, 'Erro ao atualizar status da obrigacao.');
  }

  Future<List<ObrigacaoFiscal>> listarLembretesPendentes() async {
    final response = await http.get(
      Uri.parse(
        TenantContext.applyToUrl(ApiLinks.lembretesPendentesObrigacaoFiscal),
      ),
      headers: TenantContext.jsonHeaders,
    );

    final body = _decodeBody(response.bodyBytes);
    if (response.statusCode == 200) {
      if (body is List) {
        return body
            .whereType<Map>()
            .map((item) => ObrigacaoFiscal.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
      return const [];
    }

    throw ObrigacaoFiscalException(
      _extractErrorMessage(body) ??
          'Erro ao listar lembretes de obrigacoes (${response.statusCode}).',
    );
  }

  ObrigacaoFiscal _parseObrigacao(http.Response response, String message) {
    final body = _decodeBody(response.bodyBytes);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body is Map<String, dynamic>) {
        return ObrigacaoFiscal.fromJson(body);
      }
      if (body is Map) {
        return ObrigacaoFiscal.fromJson(Map<String, dynamic>.from(body));
      }
    }
    throw ObrigacaoFiscalException(_extractErrorMessage(body) ?? message);
  }

  dynamic _decodeBody(List<int> bodyBytes) {
    if (bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(bodyBytes));
  }

  String? _extractErrorMessage(dynamic body) {
    if (body is Map) {
      return body['message']?.toString() ??
          body['error']?.toString() ??
          body['response']?['mensagem']?.toString();
    }
    return null;
  }
}

class ObrigacaoFiscalException implements Exception {
  final String message;

  const ObrigacaoFiscalException(this.message);

  @override
  String toString() => message;
}

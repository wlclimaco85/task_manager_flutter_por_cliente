import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class NfseCaller {
  Future<Map<String, dynamic>> emitir({
    required String municipio,
    required String cnpjTomador,
    required String nomeTomador,
    required String descricaoServico,
    required double valor,
    required double aliquotaIss,
    required String cnae,
    required String codigoTributacao,
    String? empresaId,
    int? nfseId,
  }) async {
    final url = ApiLinks.nfseEmitir;
    final body = buildEmitirBody(
      municipio: municipio,
      cnpjTomador: cnpjTomador,
      nomeTomador: nomeTomador,
      descricaoServico: descricaoServico,
      valor: valor,
      aliquotaIss: aliquotaIss,
      cnae: cnae,
      codigoTributacao: codigoTributacao,
      empresaId: empresaId,
      nfseId: nfseId,
    );
    final response = await TenantContext.post(url, body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfseException(
      _extractError(response, 'Falha ao emitir NFSe'),
      statusCode: response.statusCode,
    );
  }

  static Map<String, dynamic> buildEmitirBody({
    required String municipio,
    required String cnpjTomador,
    required String nomeTomador,
    required String descricaoServico,
    required double valor,
    required double aliquotaIss,
    required String cnae,
    required String codigoTributacao,
    String? empresaId,
    int? nfseId,
  }) =>
      {
        'municipio': municipio,
        'tomadorCnpj': cnpjTomador,
        'tomadorNome': nomeTomador,
        'servicoDescricao': descricaoServico,
        'valor': valor,
        'aliquotaIss': aliquotaIss,
        'cnae': cnae,
        'codTributacao': codigoTributacao,
        if (empresaId != null)
          'empresaId': int.tryParse(empresaId) ?? empresaId,
        if (nfseId != null) 'nfseId': nfseId,
      };

  Future<Map<String, dynamic>> consultar(String numero) async {
    final url = ApiLinks.nfseStatusNumero(numero);
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfseException(
      _extractError(response, 'NFSe não encontrada'),
      statusCode: response.statusCode,
    );
  }

  Future<Map<String, dynamic>> cancelar({
    required String numero,
    required String motivo,
    int? nfseId,
  }) async {
    final url = ApiLinks.nfseCancelar;
    final body = buildCancelarBody(
      numero: numero,
      motivo: motivo,
      nfseId: nfseId,
    );
    final response = await TenantContext.post(url, body);
    if (response.statusCode == 200 || response.statusCode == 204) {
      if (response.body.isEmpty) return {'status': 'cancelado'};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw NfseException(
      _extractError(response, 'Falha ao cancelar NFSe'),
      statusCode: response.statusCode,
    );
  }

  static Map<String, dynamic> buildCancelarBody({
    required String numero,
    required String motivo,
    String? empresaId,
    String? municipio,
    int? nfseId,
  }) =>
      {
        'nfseNumber': numero,
        'motivo': motivo,
        if (empresaId != null)
          'empresaId': int.tryParse(empresaId) ?? empresaId,
        if (municipio != null) 'municipio': municipio,
        if (nfseId != null) 'nfseId': nfseId,
      };

  Future<List<Map<String, dynamic>>> auditoria() async {
    final url = ApiLinks.nfseAuditoria;
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(url)),
      headers: TenantContext.headers,
    );
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.cast<Map<String, dynamic>>();
      }
      if (body is Map && body['content'] is List) {
        return (body['content'] as List).cast<Map<String, dynamic>>();
      }
      return [];
    }
    throw NfseException(
      _extractError(response, 'Falha ao buscar auditoria'),
      statusCode: response.statusCode,
    );
  }

  String _extractError(http.Response response, String fallback) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        for (final key in ['mensagem', 'message', 'error', 'motivoRejeicao']) {
          final value = body[key];
          if (value != null && value.toString().trim().isNotEmpty) {
            return value.toString();
          }
        }
      }
    } catch (_) {}
    return '$fallback (status ${response.statusCode})';
  }
}

class NfseException implements Exception {
  final String message;
  final int statusCode;
  const NfseException(this.message, {this.statusCode = -1});
  @override
  String toString() => 'NfseException($statusCode): $message';
}

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../utils/app_logger.dart';

/// Consulta publica de CEP (ViaCEP e, se falhar, BrasilAPI). GET simples, SEM Authorization nem cabecalhos de
/// tenant: o NetworkCaller os envia a qualquer URL, o que vaza o token e faz a web bloquear a chamada por CORS.
class ConsultaCepService {
  ConsultaCepService._();

  static const Duration _timeout = Duration(seconds: 10);

  /// Devolve `{logradouro, bairro, localidade, uf, complemento}`; `{'erro': true}` se o CEP nao existe;
  /// null se nenhum servico respondeu.
  static Future<Map<String, dynamic>?> consultar(String cepRaw) async {
    final cep = cepRaw.replaceAll(RegExp(r'\D'), '');
    if (cep.length != 8) return null;

    final viaCep = await _getJson('https://viacep.com.br/ws/$cep/json/');
    if (viaCep != null) {
      return viaCep['erro'] == true ? {'erro': true} : mapearViaCep(viaCep);
    }
    final brasilApi = await _getJson('https://brasilapi.com.br/api/cep/v1/$cep');
    return mapearBrasilApi(brasilApi);
  }

  static Future<Map<String, dynamic>?> _getJson(String url) async {
    try {
      final resp = await http.get(Uri.parse(url)).timeout(_timeout);
      if (resp.statusCode != 200) {
        AppLogger.i.warn('[ConsultaCep] $url respondeu ${resp.statusCode}');
        return null;
      }
      final body = jsonDecode(utf8.decode(resp.bodyBytes, allowMalformed: true));
      return body is Map ? Map<String, dynamic>.from(body) : null;
    } catch (e) {
      AppLogger.i.warn('[ConsultaCep] falha ao consultar $url: $e');
      return null;
    }
  }

  @visibleForTesting
  static Map<String, dynamic> mapearViaCep(Map<String, dynamic> d) => {
        'logradouro': (d['logradouro'] ?? '').toString(),
        'bairro': (d['bairro'] ?? '').toString(),
        'localidade': (d['localidade'] ?? '').toString(),
        'uf': (d['uf'] ?? '').toString(),
        'complemento': (d['complemento'] ?? '').toString(),
      };

  @visibleForTesting
  static Map<String, dynamic>? mapearBrasilApi(Map<String, dynamic>? d) {
    if (d == null) return null;
    final cidade = (d['city'] ?? '').toString();
    if (cidade.isEmpty) return null;
    return {
      'logradouro': (d['street'] ?? '').toString(),
      'bairro': (d['neighborhood'] ?? '').toString(),
      'localidade': cidade,
      'uf': (d['state'] ?? '').toString(),
      'complemento': '',
    };
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/app_logger.dart';
import 'network_caller.dart';

class ConsultaCnpjService {
  ConsultaCnpjService._();

  static const Duration _timeout = Duration(seconds: 12);

  /// Consulta dados de CNPJ no backend ou, se ele falhar, nas APIs publicas (ReceitaWS e BrasilAPI).
  /// Retorna os dados cadastrais estruturados ou null se falhar/inválido.
  static Future<Map<String, dynamic>?> consultar(String cnpjRaw) async {
    final cnpj = cnpjRaw.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length != 14) return null;

    try {
      // 1. Tenta endpoint backend /api/receitaws/cnpj/{cnpj}
      var resp = await NetworkCaller()
          .getRequest('${ApiLinks.baseUrl}/api/receitaws/cnpj/$cnpj');
      if (resp.isSuccess && resp.body != null && resp.body is Map) {
        final b = resp.body as Map;
        final data = b['data'] is Map ? b['data'] as Map : b;
        return Map<String, dynamic>.from(data);
      }

      // 2. Fallback backend /api/parceiro/consulta-cnpj/{cnpj}
      resp = await NetworkCaller()
          .getRequest('${ApiLinks.baseUrl}/api/parceiro/consulta-cnpj/$cnpj');
      if (resp.isSuccess && resp.body != null && resp.body is Map) {
        final b = resp.body as Map;
        if (b['data'] != null && b['data'] is Map) {
          return Map<String, dynamic>.from(b['data'] as Map);
        }
      }
    } catch (e) {
      AppLogger.i.warn('[ConsultaCnpj] backend falhou para $cnpj: $e');
    }

    // 3. APIs publicas, direto do app.
    return consultarPublico(cnpj);
  }

  /// ReceitaWS e, se falhar, BrasilAPI. IMPORTANTE: GET simples, sem Authorization nem cabecalhos de tenant
  /// (o NetworkCaller os envia a qualquer URL: vazaria o token e a web bloquearia a chamada por CORS).
  static Future<Map<String, dynamic>?> consultarPublico(String cnpjRaw) async {
    final cnpj = cnpjRaw.replaceAll(RegExp(r'\D'), '');
    if (cnpj.length != 14) return null;

    final receitaWs = await _getJson('https://www.receitaws.com.br/v1/cnpj/$cnpj');
    final dadosReceitaWs = mapearReceitaWs(receitaWs);
    if (dadosReceitaWs != null) return dadosReceitaWs;

    final brasilApi = await _getJson('https://brasilapi.com.br/api/cnpj/v1/$cnpj');
    final dadosBrasilApi = mapearBrasilApi(brasilApi);
    if (dadosBrasilApi == null) {
      AppLogger.i.warn('[ConsultaCnpj] ReceitaWS e BrasilAPI nao retornaram dados para $cnpj');
    }
    return dadosBrasilApi;
  }

  static Future<Map<String, dynamic>?> _getJson(String url) async {
    try {
      final resp = await http.get(Uri.parse(url)).timeout(_timeout);
      if (resp.statusCode != 200) {
        AppLogger.i.warn('[ConsultaCnpj] $url respondeu ${resp.statusCode}');
        return null;
      }
      final body = jsonDecode(utf8.decode(resp.bodyBytes, allowMalformed: true));
      return body is Map ? Map<String, dynamic>.from(body) : null;
    } catch (e) {
      AppLogger.i.warn('[ConsultaCnpj] falha ao consultar $url: $e');
      return null;
    }
  }

  /// Resposta da ReceitaWS (`status: OK`) para o contrato usado nos cadastros; null se nao for valida.
  @visibleForTesting
  static Map<String, dynamic>? mapearReceitaWs(Map<String, dynamic>? b) {
    if (b == null) return null;
    if (b['status'] == 'ERROR' || (b['status'] != 'OK' && b['nome'] == null)) return null;
    return {
      'nome': b['nome'],
      'razaoSocial': b['nome'],
      'nomeFantasia': b['fantasia'],
      'logradouro': b['logradouro'],
      'rua': b['logradouro'],
      'numero': b['numero'],
      'complemento': b['complemento'],
      'bairro': b['bairro'],
      'municipio': b['municipio'],
      'cidade': b['municipio'],
      'uf': b['uf'],
      'estado': b['uf'],
      'cep': b['cep'],
      'telefone': b['telefone'],
      'email': b['email'],
      'situacao': b['situacao'],
    };
  }

  /// Resposta da BrasilAPI (`/cnpj/v1`) para o mesmo contrato; null se nao tiver razao social.
  @visibleForTesting
  static Map<String, dynamic>? mapearBrasilApi(Map<String, dynamic>? b) {
    if (b == null || (b['razao_social'] ?? '').toString().trim().isEmpty) return null;
    final tipo = (b['descricao_tipo_de_logradouro'] ?? '').toString().trim();
    final logradouro = (b['logradouro'] ?? '').toString().trim();
    final rua = [tipo, logradouro].where((e) => e.isNotEmpty).join(' ');
    final cep = (b['cep'] ?? '').toString().padLeft(8, '0');
    return {
      'nome': b['razao_social'],
      'razaoSocial': b['razao_social'],
      'nomeFantasia': b['nome_fantasia'],
      'logradouro': rua,
      'rua': rua,
      'numero': b['numero'],
      'complemento': b['complemento'],
      'bairro': b['bairro'],
      'municipio': b['municipio'],
      'cidade': b['municipio'],
      'uf': b['uf'],
      'estado': b['uf'],
      'cep': cep,
      'telefone': b['ddd_telefone_1'],
      'email': b['email'],
      'situacao': b['descricao_situacao_cadastral'],
    };
  }
}

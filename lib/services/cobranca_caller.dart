import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import 'package:flutter/foundation.dart';

class CobrancaCaller {
  static Future<List<dynamic>> listarVencidos() async {
    try {
      final response = await TenantContext.get(ApiLinks.cobrancaVencidos);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? body['content'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar vencidos: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> executarRegua() async {
    try {
      final response = await TenantContext.post(ApiLinks.cobrancaExecutarRegua, {});
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body is Map ? body : {'response': body}};
      }
      return {
        'success': false,
        'message': body['mensagem'] ?? body['message'] ?? 'Erro ao executar régua',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<Map<String, dynamic>> registrarAcao(Map<String, dynamic> data) async {
    try {
      final response = await TenantContext.post(ApiLinks.cobrancaAcoes, data);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body is Map ? body : {'response': body}};
      }
      return {
        'success': false,
        'message': body['mensagem'] ?? body['message'] ?? 'Erro ao registrar ação',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<List<dynamic>> listarAcoesCliente(int clienteId) async {
    try {
      final url = ApiLinks.cobrancaAcoesCliente(clienteId);
      final response = await TenantContext.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? body['content'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar ações: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listarRegras() async {
    try {
      final response = await TenantContext.get(ApiLinks.cobrancaRegras);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? body['content'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar regras: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> salvarRegra(Map<String, dynamic> data, {String? id}) async {
    try {
      http.Response response;
      if (id != null) {
        response = await TenantContext.put(ApiLinks.cobrancaRegra(id), data);
      } else {
        response = await TenantContext.post(ApiLinks.cobrancaRegras, data);
      }
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body is Map ? body : {'response': body}};
      }
      return {
        'success': false,
        'message': body['mensagem'] ?? body['message'] ?? 'Erro ao salvar regra',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<bool> deletarRegra(String id) async {
    try {
      final response = await TenantContext.delete(ApiLinks.cobrancaRegra(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Erro ao deletar regra: $e');
      return false;
    }
  }
}

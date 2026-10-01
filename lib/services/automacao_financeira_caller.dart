import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import 'package:flutter/foundation.dart';

class AutomacaoFinanceiraCaller {
  static Future<List<dynamic>> listar() async {
    try {
      final response = await TenantContext.get(ApiLinks.automacoesFinanceiras);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? body['content'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar automacoes: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> salvar(Map<String, dynamic> data, {String? id}) async {
    try {
      http.Response response;
      if (id != null) {
        response = await TenantContext.put(ApiLinks.automacaoFinanceira(id), data);
      } else {
        response = await TenantContext.post(ApiLinks.automacoesFinanceiras, data);
      }
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body is Map ? body : {'response': body}};
      }
      return {
        'success': false,
        'message': body['mensagem'] ?? body['message'] ?? 'Erro ao salvar automacao',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<bool> deletar(String id) async {
    try {
      final response = await TenantContext.delete(ApiLinks.automacaoFinanceira(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Erro ao deletar automacao: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> executar(String id) async {
    try {
      final response = await TenantContext.post(ApiLinks.executarAutomacaoFinanceira(id), {});
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body is Map ? body : {'response': body}};
      }
      return {
        'success': false,
        'message': body['mensagem'] ?? body['message'] ?? 'Erro ao executar automacao',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<List<dynamic>> logs(String id) async {
    try {
      final response = await TenantContext.get(ApiLinks.logsAutomacaoFinanceira(id));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? body['content'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar logs: $e');
      return [];
    }
  }
}

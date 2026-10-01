import 'dart:convert';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';
import 'package:flutter/foundation.dart';

class RenegociacaoCaller {
  static Future<List<dynamic>> listar() async {
    try {
      final response = await TenantContext.get(ApiLinks.renegociacao);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? body['content'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar renegociacoes: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> buscarPorId(String id) async {
    try {
      final response = await TenantContext.get(ApiLinks.renegociacaoById(id));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map) return body.cast<String, dynamic>();
        return {'data': body};
      }
      return {};
    } catch (e) {
      debugPrint('Erro ao buscar renegociacao: $e');
      return {};
    }
  }

  static Future<Map<String, dynamic>> criar(Map<String, dynamic> dados) async {
    try {
      final response = await TenantContext.post(ApiLinks.renegociacao, dados);
      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': body is Map ? body : {'response': body}};
      }
      return {
        'success': false,
        'message': body['mensagem'] ?? body['message'] ?? 'Erro ao criar acordo',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }
}

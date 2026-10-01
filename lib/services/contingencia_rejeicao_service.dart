import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class ContingenciaRejeicaoService {
  Future<List<Map<String, dynamic>>> listarFilaContingencia() async {
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.listarContingencia)),
      headers: TenantContext.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      final data = body['data'];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }

    throw Exception('Erro ao listar fila de contingência (${response.statusCode})');
  }

  Future<List<Map<String, dynamic>>> listarLogsRejeicao() async {
    final response = await http.get(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.listarRejeicoes)),
      headers: TenantContext.jsonHeaders,
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body is List) {
        return body.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      final data = body['data'];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }

    throw Exception('Erro ao listar logs de rejeição (${response.statusCode})');
  }

  Future<bool> reenviarContingencia(int id) async {
    final response = await http.post(
      Uri.parse(TenantContext.applyToUrl(ApiLinks.reenviarContingencia(id))),
      headers: TenantContext.jsonHeaders,
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }
}

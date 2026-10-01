import 'dart:convert';
import '../../../utils/api_links.dart';
import '../../../utils/tenant_context.dart';
import 'package:flutter/foundation.dart';

class ConciliacaoCaller {
  static Future<List<dynamic>> listarPendentes(int contaBancariaId) async {
    try {
      final url =
          '${ApiLinks.conciliacaoPendentes}?contaBancariaId=$contaBancariaId';
      final response = await TenantContext.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar pendentes: $e');
      return [];
    }
  }

  static Future<List<dynamic>> sugerir(int contaBancariaId) async {
    try {
      final url = ApiLinks.conciliacaoSugestoes(contaBancariaId);
      final response = await TenantContext.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao buscar sugestoes: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> conciliar({
    required int transacaoId,
    required int lancamentoId,
    required String lancamentoTipo,
    String observacao = '',
  }) async {
    try {
      final body = {
        'transacaoId': transacaoId,
        'lancamentoId': lancamentoId,
        'lancamentoTipo': lancamentoTipo,
        'observacao': observacao,
      };
      final response =
          await TenantContext.post(ApiLinks.conciliacaoConciliar, body);
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data is Map ? data : {'response': data}
        };
      }
      return {
        'success': false,
        'message': data['mensagem'] ??
            data['message'] ??
            'Erro ao conciliar',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<Map<String, dynamic>> autoConciliar(
      int contaBancariaId) async {
    try {
      final url = ApiLinks.conciliacaoAuto(contaBancariaId);
      final response = await TenantContext.post(url, {});
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': data is Map ? data : {'response': data}
        };
      }
      return {
        'success': false,
        'message': data['mensagem'] ??
            data['message'] ??
            'Erro na auto-conciliacao',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erro ao conectar: $e'};
    }
  }

  static Future<bool> desfazerConciliacao(int conciliacaoId) async {
    try {
      final url = ApiLinks.conciliacaoDesfazer(conciliacaoId);
      final response = await TenantContext.delete(url);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Erro ao desfazer conciliacao: $e');
      return false;
    }
  }

  static Future<List<dynamic>> listarConciliacoes({
    int? contaBancariaId,
    String? dataInicio,
    String? dataFim,
  }) async {
    try {
      final params = <String, String>{};
      if (contaBancariaId != null) {
        params['contaBancariaId'] = contaBancariaId.toString();
      }
      if (dataInicio != null) params['dataInicio'] = dataInicio;
      if (dataFim != null) params['dataFim'] = dataFim;
      final query =
          params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final url =
          '${ApiLinks.conciliacaoListar}${query.isNotEmpty ? '?$query' : ''}';
      final response = await TenantContext.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) return body['data'] ?? body['dados'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar conciliacoes: $e');
      return [];
    }
  }

  static Future<List<dynamic>> listarLancamentos(int? empresaId) async {
    try {
      final url = empresaId != null
          ? '${ApiLinks.lancamentosFinanceiros}?empresaId=$empresaId'
          : ApiLinks.lancamentosFinanceiros;
      final response = await TenantContext.get(url);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is List) return body;
        if (body is Map) {
          return body['data'] ?? body['dados'] ?? body['content'] ?? [];
        }
      }
      return [];
    } catch (e) {
      debugPrint('Erro ao listar lancamentos: $e');
      return [];
    }
  }
}

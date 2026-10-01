import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/alimento_model.dart';
import '../models/diario_nutricional_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class DiarioNutricionalService {
  static Future<DiarioNutricionalResumo?> resumo(DateTime data) async {
    try {
      final response = await TenantContext.get(
          ApiLinks.diarioNutricionalResumo(_formatDate(data)));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return DiarioNutricionalResumo.fromJson(
              Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar diario nutricional: $e');
    }
    return null;
  }

  static Future<List<Alimento>> listarAlimentos({String? busca}) async {
    try {
      final response = await TenantContext.get(ApiLinks.allAlimentos);
      if (response.statusCode != 200) return const [];
      final decoded = jsonDecode(response.body);
      final list = _extractList(decoded);
      final alimentos = list
          .whereType<Map>()
          .map((e) => Alimento.fromJson(Map<String, dynamic>.from(e)))
          .where((a) => a.ativo != false)
          .toList();
      final query = busca?.toLowerCase().trim() ?? '';
      if (query.isEmpty) return alimentos;
      return alimentos
          .where((a) => (a.nome ?? '').toLowerCase().contains(query))
          .toList();
    } catch (e) {
      debugPrint('Erro ao listar alimentos: $e');
      return const [];
    }
  }

  static Future<DiarioNutricionalRefeicao?> registrarRefeicao({
    required DateTime data,
    required String tipo,
    String? fotoBase64,
  }) async {
    try {
      final body = {
        'data': _formatDate(data),
        'tipo': tipo,
        if (fotoBase64 != null && fotoBase64.isNotEmpty) 'foto': fotoBase64,
      };
      final response =
          await TenantContext.post(ApiLinks.diarioNutricionalRefeicoes, body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) {
          return DiarioNutricionalRefeicao.fromJson(
              Map<String, dynamic>.from(decoded));
        }
      }
    } catch (e) {
      debugPrint('Erro ao registrar refeicao: $e');
    }
    return null;
  }

  static Future<bool> registrarItem({
    required int refeicaoId,
    required int alimentoId,
    required double quantidadeGramas,
  }) async {
    try {
      final response = await TenantContext.post(
        ApiLinks.diarioNutricionalItens,
        {
          'refeicaoId': refeicaoId,
          'alimentoId': alimentoId,
          'quantidadeGramas': quantidadeGramas,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro ao registrar item do diario nutricional: $e');
      return false;
    }
  }

  static Future<bool> removerItem(int id) async {
    try {
      final response =
          await TenantContext.delete(ApiLinks.diarioNutricionalItem(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Erro ao remover item do diario nutricional: $e');
      return false;
    }
  }

  static List<dynamic> _extractList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      for (final key in ['data', 'content', 'items', 'registros']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  static String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/hidratacao_model.dart';
import '../utils/api_links.dart';
import '../utils/tenant_context.dart';

class HidratacaoService {
  static Future<HidratacaoResumo?> resumo() async {
    try {
      final response = await TenantContext.get(ApiLinks.hidratacaoResumo);
      if (response.statusCode == 200) {
        return HidratacaoResumo.fromJson(jsonDecode(response.body));
      }
    } catch (e) {
      debugPrint('Erro ao carregar hidratacao: $e');
    }
    return null;
  }

  static Future<bool> registrar(int quantidadeMl) async {
    try {
      final response = await TenantContext.post(
        ApiLinks.hidratacaoRegistros,
        {'quantidadeMl': quantidadeMl},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Erro ao registrar hidratacao: $e');
      return false;
    }
  }

  static Future<bool> salvarMeta({
    required int metaDiariaMl,
    required int volumeCopoMl,
  }) async {
    try {
      final response = await TenantContext.put(
        ApiLinks.hidratacaoMeta,
        {
          'metaDiariaMl': metaDiariaMl,
          'volumeCopoMl': volumeCopoMl,
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erro ao salvar meta de hidratacao: $e');
      return false;
    }
  }

  static Future<bool> remover(int id) async {
    try {
      final response = await TenantContext.delete(ApiLinks.hidratacaoRegistro(id));
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Erro ao remover registro de hidratacao: $e');
      return false;
    }
  }
}

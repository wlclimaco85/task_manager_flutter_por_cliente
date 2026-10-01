import 'dart:io';

import '../models/tela_model.dart';
import '../models/network_response.dart';
import '../utils/api_links.dart';
import 'network_caller.dart';
import '../utils/app_logger.dart';

class TelaService {
  /// Carrega a lista dinâmica de telas disponíveis do backend via /api/telas
  /// Lança exceção em caso de erro para permitir que o caller diferencie
  static Future<List<Tela>> listarTelas() async {
    try {
      final NetworkResponse response = await NetworkCaller().getRequest(
        '${ApiLinks.baseUrl}/api/telas',
      );

      if (response.isSuccess && response.body != null) {
        // Extrai dados do envelope de resposta: {data: {dados: [...]}}
        final dados = response.body!['data']?['dados'] ?? response.body!['data'] ?? [];

        if (dados is List) {
          return dados
              .map((json) => Tela.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      return [];
    } catch (e, st) {
      if (e is FormatException) {
        // JSON parsing failed
        rethrow;
      } else if (e is SocketException) {
        // Network error
        rethrow;
      } else {
        // Unknown error
        rethrow;
      }
    }
  }
}

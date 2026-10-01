import 'package:flutter/material.dart';
import '../models/network_response.dart';
import './network_caller.dart';
import '../utils/api_links.dart';

class BaixaCaller {
  /// Desfazer baixa de conta (tipo = "pagar" ou "receber")
  static Future<NetworkResponse> desfazerBaixa({
    required String tipo, // "pagar" ou "receber"
    required int id,
  }) async {
    if (tipo != 'pagar' && tipo != 'receber') {
      throw ArgumentError('Tipo inválido: deve ser "pagar" ou "receber".');
    }
    String url = ApiLinks.desfazerContaReceber(id.toString());
    if (tipo == 'pagar') {
      url = ApiLinks.desfazerContaPagar(id.toString());
    }
    try {
      final NetworkResponse response = await NetworkCaller().postRequest(
        url,
        {"id": id},
      );
      return response;
    } catch (e) {
      debugPrint('Erro ao desfazer baixa: $e');
      rethrow;
    }
  }
}

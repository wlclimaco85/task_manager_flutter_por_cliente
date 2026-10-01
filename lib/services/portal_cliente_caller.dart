// lib/services/portal_cliente_caller.dart
import 'package:flutter/material.dart';
import 'package:task_manager_flutter/models/portal_cliente_resumo_model.dart';
import 'package:task_manager_flutter/utils/api_links.dart';
import 'package:task_manager_flutter/services/network_caller.dart';
import 'package:task_manager_flutter/utils/app_logger.dart';

class PortalClienteCaller {
  /// Busca resumo do portal do cliente no endpoint /api/portal-cliente/resumo
  /// Retorna saldo, documentos pendentes e alertas
  Future<PortalClienteResumo> fetchResumo(
    BuildContext context,
    int empresaId,
  ) async {
    try {
      final url = '${ApiLinks.portalClienteResumo}?empresaId=$empresaId';
      final response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        final data = response.body!;

        // Response do endpoint tem formato: { data: {...}, response: {...} }
        if (data['data'] != null) {
          return PortalClienteResumo.fromJson(data['data']);
        }

        L.d('Resposta inesperada do endpoint portal-cliente/resumo');
        return PortalClienteResumo(saldo: 0, docsPendentes: 0, alertas: 0);
      }

      L.d('Erro ao buscar resumo portal cliente: ${response.statusCode}');
      return PortalClienteResumo(saldo: 0, docsPendentes: 0, alertas: 0);
    } catch (e) {
      L.e('Exceção ao buscar resumo portal cliente: $e');
      return PortalClienteResumo(saldo: 0, docsPendentes: 0, alertas: 0);
    }
  }
}

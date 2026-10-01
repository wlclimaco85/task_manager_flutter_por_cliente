import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/alert_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/tenant_context.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

class AlertCaller {
  Future<List<Alert>> fetchAllAlerts(BuildContext context) async {
    List<Alert>? model = [];
    AlertResponse models;
    try {
      final NetworkResponse response =
          await NetworkCaller().getRequests(ApiLinks.allAlerts, context);
      String jsonString;

      if (response.statusCode == 200 && response.body != null) {
        jsonString = json.encode(response.body);
        models = AlertResponse.fromJson(response.body!);
        model.addAll(models.account ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  Future<List<Alert>> fetchItensAVenda(BuildContext context) async {
    List<Alert>? model = [];
    AlertResponse models;
    if (AuthUtility.userInfo?.data?.id != null) {
      try {
        final NetworkResponse response = await NetworkCaller().getRequests(
            '${ApiLinks.alertFindByUser}${AuthUtility.userInfo?.data?.id}',
            context);
        String jsonString;

        if (response.statusCode == 200 && response.body != null) {
          jsonString = json.encode(response.body);
          models = AlertResponse.fromJson(response.body!);
          model.addAll(models.account ?? []);
        } else {
          L.d('Erro: Nenhum dado retornado');
        }
      } catch (e) {
        L.d('Erro: $e'); // Log do erro
        throw Exception('Erro ao carregar itens à venda: $e');
      }
      return model;
    }
    return model;
  }

  /// Busca notificações agregadas do endpoint completo `/api/notificacoes`.
  ///
  /// Diferente de [fetchItensAVenda] (que só cobre eventos pontuais via
  /// `/api/alert/byUser/{id}`), este endpoint também retorna alertas baseados
  /// em data: alvará vencendo, CP/CR vencidas e a vencer — além dos mesmos
  /// eventos pontuais (chamado novo, mensagem de chat, GED, comunicado),
  /// já que o backend lê a tabela de Alert internamente (`inferirTipo`).
  ///
  /// Mapeia o `NotificacaoDTO` (`tipo`/`mensagem`/`dataVencimento`/`id`) para
  /// o `Alert` model já consumido pelo sino (`texto`/`data`/`status`).
  Future<List<Alert>> fetchNotificacoes(BuildContext context,
      {int diasAviso = 30}) async {
    List<Alert> model = [];
    final empresaId = TenantContext.empresaId;
    try {
      final query = StringBuffer('?diasAviso=$diasAviso');
      if (empresaId != null) {
        query.write('&empresaId=$empresaId');
      }
      final response =
          await TenantContext.get('${ApiLinks.baseUrl}/api/notificacoes$query');

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List raw = body is List
            ? body
            : (body is Map
                ? (body['data'] ??
                    body['dados'] ??
                    body['content'] ??
                    body['items'] ??
                    [])
                : []);

        model = raw.whereType<Map>().map((item) {
          final n = Map<String, dynamic>.from(item);
          final dataVencimento = n['dataVencimento']?.toString();
          return Alert(
            id: (n['id'] ?? n['referenciaId'] ?? 0) is int
                ? (n['id'] ?? n['referenciaId'] ?? 0) as int
                : int.tryParse((n['id'] ?? n['referenciaId']).toString()) ?? 0,
            idUserDestino: AuthUtility.userInfo?.data?.id ?? 0,
            // DateTime.parse exige um formato válido; quando não há data de
            // vencimento (eventos pontuais), usamos o instante atual.
            data: (dataVencimento != null && dataVencimento.isNotEmpty)
                ? dataVencimento
                : DateTime.now().toIso8601String(),
            texto: n['mensagem']?.toString() ?? n['texto']?.toString() ?? '',
            status: n['tipo']?.toString() ?? 'NOVO',
          );
        }).toList();
      } else {
        L.d('Erro: Nenhum dado retornado de /api/notificacoes (status ${response.statusCode})');
      }
    } catch (e) {
      L.d('Erro: $e');
      throw Exception('Erro ao carregar notificações: $e');
    }
    return model;
  }

  /// Marca a notificação [n] como lida para o login logado.
  ///
  /// POST /api/notificacoes/marcar-lida com body
  /// `{"notificacaoChave": "TIPO:referenciaId"}`, onde `tipo` e `referenciaId`
  /// vêm de [Alert.status] e [Alert.id] (mapeados a partir do `NotificacaoDTO`
  /// em [fetchNotificacoes]). Após essa chamada, o próximo
  /// `GET /api/notificacoes` não traz mais essa notificação.
  Future<bool> marcarNotificacaoLida(Alert n) async {
    try {
      final response = await TenantContext.post(
        '${ApiLinks.baseUrl}/api/notificacoes/marcar-lida',
        {'notificacaoChave': '${n.status}:${n.id}'},
      );
      if (response.statusCode == 200 || response.statusCode == 204) return true;
      L.d('Erro: falha ao marcar notificação como lida (status ${response.statusCode})');
      return false;
    } catch (e) {
      L.d('Erro: $e');
      return false;
    }
  }

  /// Marca todas as notificações não lidas (do login logado) como lidas.
  ///
  /// POST /api/notificacoes/marcar-todas-lidas?empresaId=...&diasAviso=...,
  /// usando os mesmos parâmetros de [fetchNotificacoes].
  Future<bool> marcarTodasNotificacoesLidas({int diasAviso = 30}) async {
    try {
      final empresaId = TenantContext.empresaId;
      final query = StringBuffer('?diasAviso=$diasAviso');
      if (empresaId != null) {
        query.write('&empresaId=$empresaId');
      }
      final response = await TenantContext.post(
        '${ApiLinks.baseUrl}/api/notificacoes/marcar-todas-lidas$query',
        {},
      );
      if (response.statusCode == 200 || response.statusCode == 204) return true;
      L.d('Erro: falha ao marcar todas as notificações como lidas (status ${response.statusCode})');
      return false;
    } catch (e) {
      L.d('Erro: $e');
      return false;
    }
  }
}

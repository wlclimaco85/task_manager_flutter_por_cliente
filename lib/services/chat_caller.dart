import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../models/chat_model.dart';
import '../../../utils/api_links.dart';
import '../../../models/network_response.dart';
import '../../services/network_caller.dart';
import '../../../models/auth_utility.dart';
import '../../../utils/tenant_context.dart';

import 'package:task_manager_flutter/utils/app_logger.dart';

/// Fix (card #473): chatId determinístico para a conversa vinculada a um
/// chamado específico. Distinto do chatId padrão de atendimento
/// ("empresa-X-parceiro-Y", 1 conversa perene por cliente) -- cada chamado
/// tem sua própria conversa separada, permitindo exibir o número do
/// chamado na tela de chat (basta parsear de volta o final da string).
/// Backend não precisa de nenhuma coluna nova: ChatWebSocketHandler só gera
/// um chatId novo quando recebe null/vazio/"0" (ver card #430) -- qualquer
/// outro valor, incluindo este, é usado como está.
String buildChamadoChatId(int empresaId, int parceiroId, int chamadoId) =>
    'empresa-$empresaId-parceiro-$parceiroId-chamado-$chamadoId';

/// Extrai o número do chamado de um chatId no formato de [buildChamadoChatId],
/// ou null se o chatId não seguir esse padrão (conversa comum, não vinculada
/// a nenhum chamado).
int? extrairChamadoIdDoChatId(String chatId) {
  final match = RegExp(r'-chamado-(\d+)$').firstMatch(chatId);
  if (match == null) return null;
  return int.tryParse(match.group(1)!);
}

class ChatCaller {
  Future<List<ChatMessage>> fetchChats(BuildContext context) async {
    List<ChatMessage>? model = [];
    ChatMessageModel models;
    try {
      // Tenta email do login primeiro, depois dados pessoais
      final login = AuthUtility.userInfo?.login;
      final dp = AuthUtility.userInfo?.data?.codDadosPessoal;
      final email = login?.email ?? dp?.email;
      if (email == null || email.isEmpty) {
        L.d('ChatCaller: email do usuario nao encontrado');
        return model;
      }
      final url = '${ApiLinks.fecthChats}?user=${Uri.encodeComponent(email)}';

      final NetworkResponse response = await NetworkCaller().getRequest(url);

      if (response.statusCode == 200 && response.body != null) {
        models = ChatMessageModel.fromJson(response.body!);
        model.addAll(models.messages ?? []);
      } else {
        // Fix card #442: antes falhava silenciosamente (sem log nenhum),
        // dificultando diagnosticar quando o backend retorna erro.
        L.d('ChatCaller: falha ao carregar chats (status ${response.statusCode})');
      }
    } catch (e) {
      L.d('Erro ao carregar chats: $e');
    }
    return model;
  }

  Future<List<ChatMessage>> fetchChatsById(
      BuildContext context, String chatId) async {
    List<ChatMessage>? model = [];
    ChatMessageModel models;
    try {
      L.d('URL de requisição: $chatId');

      final encodedId = Uri.encodeQueryComponent(chatId);
      final NetworkResponse response = await NetworkCaller()
          .getRequest('${ApiLinks.fecthChatById}$encodedId');

      if (response.statusCode == 200 && response.body != null) {
        models = ChatMessageModel.fromJson(response.body!);
        model.addAll(models.messages ?? []);
      } else {
        L.d('Erro: Nenhum dado retornado');
      }
    } catch (e) {
      L.d('Erro: $e'); // Log do erro
      throw Exception('Erro ao carregar cotações: $e');
    }
    return model;
  }

  // ── Chat Kanban ──────────────────────────────────────────────────────────
  Future<List<ChatKanbanItem>> fetchChatsKanban() async {
    try {
      final url = ApiLinks.chatKanban;
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'] ?? body;
          if (d is List) {
            lista = d;
          } else if (d is Map) {
            lista = d['dados'] ?? d['content'] ?? [];
          }
        } else if (body is List) {
          lista = body;
        }
        return lista
            .whereType<Map>()
            .map((e) => ChatKanbanItem.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } catch (e) {
      L.d('Erro ao carregar kanban de chats: $e');
    }
    return [];
  }

  // ── Transferir Chat ──────────────────────────────────────────────────────
  Future<bool> transferChat(String chatId, String usuarioDestinoId) async {
    try {
      final url = ApiLinks.chatTransfer(chatId);
      final body = {'usuarioDestinoId': usuarioDestinoId};
      final resp = await TenantContext.put(url, body);
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
      L.d('Erro ao transferir chat: ${resp.statusCode}');
    } catch (e) {
      L.d('Erro ao transferir chat: $e');
    }
    return false;
  }

  // ── Incluir participante (card #474, Fase 3) ────────────────────────────
  Future<bool> incluirParticipante(String chatId, String loginId) async {
    try {
      final requerenteId = (AuthUtility.userInfo?.login?.id ??
              AuthUtility.userInfo?.data?.id)
          ?.toString() ??
          '';
      final url =
          '${ApiLinks.baseUrl}/api/chat/$chatId/participantes?loginId=$loginId&requerenteId=$requerenteId';
      final resp = await TenantContext.post(url, {});
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
      L.d('Erro ao incluir participante: ${resp.statusCode}');
    } catch (e) {
      L.d('Erro ao incluir participante: $e');
    }
    return false;
  }

  // ── Marcar como lido ─────────────────────────────────────────────────────
  Future<bool> marcarComoLido(String chatId) async {
    try {
      final url = ApiLinks.chatMarkAsRead(chatId);
      final resp = await TenantContext.put(url, {});
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
    } catch (e) {
      L.d('Erro ao marcar chat como lido: $e');
    }
    return false;
  }

  // ── Usuários do setor para transferência ─────────────────────────────────
  Future<List<Map<String, String>>> fetchUsuariosSetor(String setorId) async {
    try {
      final url = '${ApiLinks.chatUsuariosSetor}?setorId=${Uri.encodeComponent(setorId)}';
      final resp = await TenantContext.get(url);
      if (resp.statusCode == 200) {
        final body = jsonDecode(resp.body);
        List lista = [];
        if (body is Map) {
          final d = body['data'] ?? body;
          if (d is List) lista = d;
          else if (d is Map) lista = d['dados'] ?? d['content'] ?? [];
        } else if (body is List) {
          lista = body;
        }
        return lista.whereType<Map>().map((e) => {
          'id': (e['id'] ?? e['usuarioId']).toString(),
          'nome': (e['nome'] ?? e['login'] ?? e['email'] ?? 'Usuário').toString(),
        }).toList();
      }
    } catch (e) {
      L.d('Erro ao carregar usuários do setor: $e');
    }
    return [];
  }

  // ── Pegar atendimento (Card #448 Fase 1) ─────────────────────────────────
  Future<bool> pegarAtendimento(String chatId, int usuarioId) async {
    try {
      final url = ApiLinks.chatPickup(chatId, usuarioId);
      final resp = await TenantContext.put(url, {});
      if (resp.statusCode == 200) return true;
      if (resp.statusCode == 409) {
        L.d('Atendimento $chatId ja possui responsavel');
      } else {
        L.d('Erro ao pegar atendimento: ${resp.statusCode}');
      }
    } catch (e) {
      L.d('Erro ao pegar atendimento: $e');
    }
    return false;
  }

  // ── Atualizar status do chat ─────────────────────────────────────────────
  Future<bool> atualizarStatus(String chatId, String novoStatus) async {
    try {
      final url = ApiLinks.chatFinalize(chatId);
      final body = {'status': novoStatus};
      final resp = await TenantContext.put(url, body);
      if (resp.statusCode == 200 || resp.statusCode == 204) return true;
    } catch (e) {
      L.d('Erro ao atualizar status do chat: $e');
    }
    return false;
  }
}

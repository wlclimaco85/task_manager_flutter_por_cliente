// test/services/test_helper.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';

const String kTestEmail = 'wlclimaco@gmail.com';
const String kTestPassword = '123456';

// Token e dados de sessão compartilhados entre todos os testes
String? _cachedToken;
int? _cachedEmpresaId;
int? _cachedParceiroId;
int? _cachedAplicativoId;
int? _cachedUserId;

// Getters públicos usados pelos testes para montar payloads com FKs corretos
int? get cachedEmpresaId => _cachedEmpresaId;
int? get cachedParceiroId => _cachedParceiroId;
int? get cachedUserId => _cachedUserId;

/// Realiza login replicando exatamente o que o NetworkCaller faz no app.
Future<String> loginAndGetToken() async {
  if (_cachedToken != null) return _cachedToken!;

  // Mesmo body que NetworkCaller.postRequest monta para o login
  final body = {
    'email': kTestEmail,
    'password': kTestPassword,
    'empresa': {},
    'aplicativo': {},
    'audit': {},
  };

  final response = await http.post(
    Uri.parse(ApiLinks.login),
    headers: {
      'Content-Type': 'application/json;charset=UTF-8',
      // Header idêntico ao NetworkCaller para rotas de login
      'Authorization': 'c2Fua2h5YTpzdXA=',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, Accept',
      // SEM Accept-Encoding: gzip — evita Connection closed no ambiente de teste
    },
    body: jsonEncode(body),
  );

  expect(
    response.statusCode,
    anyOf(200, 201),
    reason: 'Login falhou: ${response.statusCode}\n${response.body}',
  );

  final decoded = jsonDecode(response.body);

  // Extrai token — pode estar em diferentes níveis dependendo do backend
  _cachedToken = decoded['token'] ??
      decoded['access_token'] ??
      decoded['data']?['token'] ??
      decoded['data']?['access_token'] ??
      decoded['login']?['token'];

  expect(_cachedToken, isNotNull,
      reason: 'Token não encontrado na resposta: ${response.body}');

  // Guarda IDs de contexto para montar os bodies de POST/PUT
  _cachedEmpresaId = decoded['login']?['empresa']?['id'] ??
      decoded['data']?['login']?['empresa']?['id'];
  _cachedParceiroId = decoded['login']?['parceiro']?['id'] ??
      decoded['data']?['login']?['parceiro']?['id'];
  _cachedAplicativoId = decoded['login']?['aplicativo']?['id'] ??
      decoded['data']?['login']?['aplicativo']?['id'];
  _cachedUserId =
      decoded['data']?['id'] ?? decoded['login']?['id'] ?? decoded['id'];

  // Se o usuário MASTER não tem empresa no login, busca a primeira disponível
  if (_cachedEmpresaId == null) {
    try {
      final empResp = await http.get(
        Uri.parse(ApiLinks.allEmpresas),
        headers: {
          'Content-Type': 'application/json;charset=UTF-8',
          'Authorization': 'Bearer $_cachedToken',
          'Access-Control-Allow-Origin': '*',
        },
      );
      if (empResp.statusCode == 200) {
        final empBody = jsonDecode(empResp.body);
        List list = [];
        if (empBody is List) {
          list = empBody;
        } else if (empBody is Map) {
          final data = empBody['data'];
          if (data is Map) {
            final dados = data['dados'] ?? data['content'] ?? data['items'];
            if (dados is List) list = dados;
          } else if (data is List) {
            list = data;
          } else {
            for (final key in ['content', 'dados', 'items']) {
              final v = empBody[key];
              if (v is List) { list = v; break; }
            }
          }
        }
        if (list.isNotEmpty) {
          _cachedEmpresaId = list.first['id'];
        }
      }
    } catch (_) {}
  }

  return _cachedToken!;
}

/// Headers autenticados — sem gzip para evitar Connection closed nos testes
Map<String, String> authHeaders(String token) => {
      'Content-Type': 'application/json;charset=UTF-8',
      'Authorization': 'Bearer $token',
      if (_cachedEmpresaId != null) 'X-Tenant-ID': _cachedEmpresaId.toString(),
      'Access-Control-Allow-Origin': '*',
    };

/// Monta o body de POST/PUT replicando o que NetworkCaller injeta automaticamente.
/// Injeta tanto o objeto aninhado (empresa.id) quanto o campo flat (empresaId)
/// porque diferentes controllers do backend aceitam formas diferentes.
Map<String, dynamic> withAudit(Map<String, dynamic> body) {
  return {
    ...body,
    if (_cachedEmpresaId != null) 'empresaId': _cachedEmpresaId,
    'empresa': {'id': _cachedEmpresaId},
    'aplicativo': {'id': _cachedAplicativoId},
    if (_cachedParceiroId != null) 'parceiroId': _cachedParceiroId,
    if (_cachedParceiroId != null) 'parceiro': {'id': _cachedParceiroId},
    'audit': {
      'empresaId': _cachedEmpresaId,
      'appId': _cachedAplicativoId,
      'parceiroId': _cachedParceiroId,
      'userLogadoId': _cachedUserId,
    },
  };
}

// ─── Matchers de status por operação ────────────────────────────────────────

void expectListOk(int statusCode, String ctx) =>
    expect(statusCode, 200,
        reason: '[$ctx] esperado 200, recebido $statusCode');

void expectInsertOk(int statusCode, String ctx) =>
    expect(statusCode, anyOf(200, 201),
        reason: '[$ctx] esperado 200 ou 201, recebido $statusCode');

void expectUpdateOk(int statusCode, String ctx) =>
    expect(statusCode, anyOf(200, 204),
        reason: '[$ctx] esperado 200 ou 204, recebido $statusCode');

void expectDeleteOk(int statusCode, String ctx) =>
    expect(statusCode, anyOf(200, 204),
        reason: '[$ctx] esperado 200 ou 204, recebido $statusCode');

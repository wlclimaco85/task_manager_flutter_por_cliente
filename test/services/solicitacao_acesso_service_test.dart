// test/services/solicitacao_acesso_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async {
    token = await loginAndGetToken();
  });

  group('Solicitacao de Acesso API', () {
    test('Criar (endpoint publico, sem token) → 201', () async {
      final email = 'qa_solicitacao_${DateTime.now().millisecondsSinceEpoch}@teste.com';
      final res = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': 'QA Teste Solicitacao',
          'email': email,
          'cpfCnpj': '99988877766',
          'senha': '123456',
        }),
      );
      expect(res.statusCode, 201,
          reason: 'Criar solicitacao esperado 201, recebido ${res.statusCode}\n${res.body}');
    });

    test('Criar duplicada (mesmo email/cpfCnpj, ainda PENDENTE) → 409', () async {
      final email = 'qa_dup_${DateTime.now().millisecondsSinceEpoch}@teste.com';
      const cpfCnpj = '11122233344';
      final body = jsonEncode({
        'nome': 'QA Dup',
        'email': email,
        'cpfCnpj': cpfCnpj,
        'senha': '123456',
      });

      final primeira = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: body,
      );
      expect(primeira.statusCode, 201, reason: 'Primeira solicitacao deveria criar');

      final segunda = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcesso),
        headers: const {'Content-Type': 'application/json'},
        body: body,
      );
      expect(segunda.statusCode, 409,
          reason: 'Duplicada esperado 409, recebido ${segunda.statusCode}\n${segunda.body}');
    });

    test('Listar pendentes (autenticado) → 200', () async {
      final res = await http.get(
        Uri.parse(ApiLinks.solicitacaoAcessoPendentes),
        headers: authHeaders(token),
      );
      expectListOk(res.statusCode, 'Listar Pendentes');

      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      expect(decoded['data'], isA<List>(),
          reason: 'Resposta deveria conter data como lista');
    });

    test('Aprovar solicitacao inexistente → 404', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcessoAprovar(999999999)),
        headers: authHeaders(token),
      );
      expect(res.statusCode, 404,
          reason: 'Aprovar id inexistente esperado 404, recebido ${res.statusCode}');
    });

    test('Rejeitar solicitacao inexistente → 404', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.solicitacaoAcessoRejeitar(999999999)),
        headers: authHeaders(token),
      );
      expect(res.statusCode, 404,
          reason: 'Rejeitar id inexistente esperado 404, recebido ${res.statusCode}');
    });
  });
}

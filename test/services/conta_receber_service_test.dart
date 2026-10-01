// test/services/conta_receber_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Contas a Receber API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allContasReceber), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Contas Receber');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createContaReceber),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'descricao': 'Recebimento Teste',
          'valor': 500.0,
          'dataVencimento': '2026-12-31',
          'status': 'ABERTO',
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Conta Receber');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateContaReceber(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'descricao': 'Recebimento Atualizado', 'valor': 750.0})),
      );
      expectUpdateOk(res.statusCode, 'Update Conta Receber');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteContaReceber(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Conta Receber');
    });
  });
}

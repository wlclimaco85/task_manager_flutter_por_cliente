// test/services/conta_pagar_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Contas a Pagar API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allContasPagar), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Contas Pagar');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createContaPagar),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'descricao': 'Conta Teste',
          'valor': 100.0,
          'dataVencimento': '2026-12-31',
          'status': 'ABERTO',
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Conta Pagar');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateContaPagar(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'descricao': 'Conta Atualizada', 'valor': 200.0})),
      );
      expectUpdateOk(res.statusCode, 'Update Conta Pagar');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteContaPagar(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Conta Pagar');
    });
  });
}

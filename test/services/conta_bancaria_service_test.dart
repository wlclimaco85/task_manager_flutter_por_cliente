// test/services/conta_bancaria_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Contas Bancárias API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allContasBancarias), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Contas Bancárias');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createContaBancaria),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'banco': 'Banco Teste',
          'agencia': '0001',
          'conta': '12345-6',
          'tipo': 'CORRENTE',
          'saldo': 0.0,
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Conta Bancária');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateContaBancaria(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'banco': 'Banco Atualizado', 'saldo': 1000.0})),
      );
      expectUpdateOk(res.statusCode, 'Update Conta Bancária');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteContaBancaria(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Conta Bancária');
    });
  });
}

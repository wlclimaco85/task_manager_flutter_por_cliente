// test/services/parceiro_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Parceiros API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allParceiros), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Parceiros');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createParceiro),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'nome': 'Parceiro Teste',
          'email': 'parceiro_teste@teste.com',
          'cpfCnpj': '00000000000',
          'tipo': 'CLIENTE',
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Parceiro');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateParceiro(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Parceiro Atualizado'})),
      );
      expectUpdateOk(res.statusCode, 'Update Parceiro');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteParceiro(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Parceiro');
    });
  });
}

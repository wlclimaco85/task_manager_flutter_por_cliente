// test/services/empresa_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;
  int? createdId;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Empresa API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allEmpresas), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Empresas');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createEmpresa),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'razaoSocial': 'Empresa Teste LTDA',
          'cnpj': '00000000000000',
          'email': 'empresa_teste@teste.com',
        })),
      );
      expectInsertOk(res.statusCode, 'Insert Empresa');
      final data = jsonDecode(res.body);
      createdId = data['id'] ?? data['data']?['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateEmpresa(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'razaoSocial': 'Empresa Atualizada LTDA'})),
      );
      expectUpdateOk(res.statusCode, 'Update Empresa');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteEmpresa(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Empresa');
    });
  });
}

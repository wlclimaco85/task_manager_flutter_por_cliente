// test/services/academia_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Academia - Listagem', () {
    test('Listar academias → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allAcademia), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Academias');
    });
  });

  group('Dieta API', () {
    int? createdId;

    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allDietas), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Dietas');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createDieta),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Dieta Teste', 'descricao': 'Gerado por teste'})),
      );
      expectInsertOk(res.statusCode, 'Insert Dieta');
      createdId = jsonDecode(res.body)['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateDieta(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Dieta Atualizada'})),
      );
      expectUpdateOk(res.statusCode, 'Update Dieta');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteDieta(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Dieta');
    });
  });

  group('Exame API', () {
    int? createdId;

    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allExames), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Exames');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createExame),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Exame Teste', 'descricao': 'Gerado por teste'})),
      );
      expectInsertOk(res.statusCode, 'Insert Exame');
      createdId = jsonDecode(res.body)['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateExame(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Exame Atualizado'})),
      );
      expectUpdateOk(res.statusCode, 'Update Exame');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteExame(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Exame');
    });
  });

  group('Medicamento API', () {
    int? createdId;

    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allMedicamentos), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Medicamentos');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createMedicamento),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Medicamento Teste', 'descricao': 'Gerado por teste'})),
      );
      expectInsertOk(res.statusCode, 'Insert Medicamento');
      createdId = jsonDecode(res.body)['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateMedicamento(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Medicamento Atualizado'})),
      );
      expectUpdateOk(res.statusCode, 'Update Medicamento');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteMedicamento(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Medicamento');
    });
  });

  group('Suplemento API', () {
    int? createdId;

    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.allSuplementos), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Suplementos');
    });

    test('Insert → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.createSuplemento),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Suplemento Teste', 'descricao': 'Gerado por teste'})),
      );
      expectInsertOk(res.statusCode, 'Insert Suplemento');
      createdId = jsonDecode(res.body)['id'];
      expect(createdId, isNotNull, reason: 'ID não retornado após insert');
    });

    test('Update → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.put(
        Uri.parse(ApiLinks.updateSuplemento(createdId.toString())),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({'nome': 'Suplemento Atualizado'})),
      );
      expectUpdateOk(res.statusCode, 'Update Suplemento');
    });

    test('Delete → 200 ou 204', () async {
      if (createdId == null) return markTestSkipped('Insert não gerou ID');
      final res = await http.delete(Uri.parse(ApiLinks.deleteSuplemento(createdId.toString())), headers: authHeaders(token));
      expectDeleteOk(res.statusCode, 'Delete Suplemento');
    });
  });
}

// test/services/ponto_service_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:task_manager_flutter/utils/api_links.dart';
import 'test_helper.dart';

void main() {
  late String token;

  setUpAll(() async { token = await loginAndGetToken(); });

  group('Ponto API', () {
    test('Listar → 200', () async {
      final res = await http.get(Uri.parse(ApiLinks.pontoListar), headers: authHeaders(token));
      expectListOk(res.statusCode, 'Listar Pontos');
    });

    test('Registrar ponto (insert) → 200 ou 201', () async {
      final res = await http.post(
        Uri.parse(ApiLinks.pontoRegistrar),
        headers: authHeaders(token),
        body: jsonEncode(withAudit({
          'tipo': 'ENTRADA',
          'dataHora': DateTime.now().toIso8601String(),
        })),
      );
      expectInsertOk(res.statusCode, 'Registrar Ponto');
    });
  });
}

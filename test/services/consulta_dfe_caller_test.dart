import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/consulta_dfe_caller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('baixar envia a chave de acesso no corpo', () async {
    String? corpo;
    final cliente = MockClient((req) async {
      corpo = req.body;
      return http.Response('{}', 200);
    });

    final r = await http.runWithClient(
        () => ConsultaDfeCaller.baixar('7', 'CHAVE44'), () => cliente);

    expect(r.success, isTrue);
    expect(jsonDecode(corpo!)['chave'], 'CHAVE44');
  });

  test('baixar devolve a mensagem de erro do backend', () async {
    final cliente = MockClient((_) async =>
        http.Response('{"message":"XML completo indisponivel"}', 404));

    final r = await http.runWithClient(
        () => ConsultaDfeCaller.baixar('7', 'CHAVE44'), () => cliente);

    expect(r.success, isFalse);
    expect(r.message, 'XML completo indisponivel');
  });
}

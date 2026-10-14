import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/services/sistema_error_reporter.dart';

void main() {
  tearDown(() => SistemaErrorReporter.instance.reset());

  test('log enviado ao backend identifica o app de origem', () async {
    final corpos = <Map<String, dynamic>>[];
    SistemaErrorReporter.instance.setClient(MockClient((http.Request req) async {
      corpos.add(jsonDecode(req.body) as Map<String, dynamic>);
      return http.Response('{}', 200);
    }));

    SistemaErrorReporter.instance
        .reportarErro(mensagem: 'falha de teste', classeOuRota: 'teste');
    await SistemaErrorReporter.instance.flushBuffer();

    expect(corpos, hasLength(1));
    expect(corpos.single['appTipo'], 'APP_CONTA_PROPRIA');
    expect(SistemaErrorReporter.appTipo, 'APP_CONTA_PROPRIA');
  });
}

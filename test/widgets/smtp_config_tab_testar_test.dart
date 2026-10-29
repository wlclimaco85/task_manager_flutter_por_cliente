import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/smtp_config_tab.dart';

void main() {
  const json = {'content-type': 'application/json; charset=utf-8'};

  testWidgets('botao Testar chama POST /testar da empresa e mostra a mensagem do backend', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      if (req.method == 'POST') {
        return http.Response(
          jsonEncode({'enviado': true, 'mensagem': 'E-mail de teste enviado para dono@exemplo.com.'}),
          200,
          headers: json,
        );
      }
      return http.Response(jsonEncode({'ativo': true, 'host': 'smtp.gmail.com', 'porta': 587}), 200, headers: json);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SmtpConfigTab(scope: SmtpConfigScope.empresa, id: 20001, nome: 'Abraco')),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('smtp_testar')));
      await tester.pumpAndSettle();

      final post = pedidos.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, endsWith('/api/smtp-config/empresa/20001/testar'));
      expect(find.text('E-mail de teste enviado para dono@exemplo.com.'), findsOneWidget);
    }, () => cliente);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('escopo parceiro nao mostra o botao Testar', (tester) async {
    final cliente = MockClient((req) async => http.Response('{}', 200, headers: json));

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SmtpConfigTab(scope: SmtpConfigScope.parceiro, id: 7, nome: 'Parceiro')),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('smtp_testar')), findsNothing);
    }, () => cliente);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}

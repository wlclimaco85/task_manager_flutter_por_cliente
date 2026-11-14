import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/email_modelos_tab.dart';
import 'package:task_manager_flutter/widgets/smtp_config_tab.dart';

void main() {
  const json = {'content-type': 'application/json; charset=utf-8'};

  Map<String, dynamic> modelo({
    required int? id,
    required String tipo,
    String origem = 'PADRAO',
    bool herdado = true,
  }) =>
      {
        'id': id,
        'tipo': tipo,
        'nome': 'Modelo $tipo',
        'assunto': 'Assunto $tipo',
        'html': '<p>{{nome}} {{codigo}} {{arquivo}} $tipo</p>',
        'origem': origem,
        'herdado': herdado,
        'somenteLeitura': herdado,
      };

  Future<void> encerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('lista os modelos do escopo da empresa e mostra a origem', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      return http.Response(
        jsonEncode([
          modelo(id: 1, tipo: 'BOAS_VINDAS'),
          modelo(id: 9, tipo: 'REDEFINIR_SENHA', origem: 'EMPRESA', herdado: false),
        ]),
        200,
        headers: json,
      );
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.empresa, id: 20001, nome: 'Abraco')),
      ));
      await tester.pumpAndSettle();

      expect(pedidos.first.url.path, endsWith('/api/email-modelos'));
      expect(pedidos.first.url.queryParameters['empresaId'], '20001');
      expect(find.text('Modelo BOAS_VINDAS'), findsOneWidget);
      expect(find.text('Padrão do sistema'), findsOneWidget);
      expect(find.text('Empresa'), findsOneWidget);
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('escopo parceiro consulta por parceiroId', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      return http.Response('[]', 200, headers: json);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.parceiro, id: 7)),
      ));
      await tester.pumpAndSettle();

      expect(pedidos.first.url.queryParameters['parceiroId'], '7');
      expect(find.text('Nenhum modelo encontrado.'), findsOneWidget);
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('personalizar um modelo herdado cria o proprio com POST no escopo', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      if (req.method == 'POST') {
        return http.Response(jsonEncode(modelo(id: 33, tipo: 'BOAS_VINDAS', origem: 'EMPRESA', herdado: false)), 201, headers: json);
      }
      return http.Response(jsonEncode([modelo(id: 1, tipo: 'BOAS_VINDAS')]), 200, headers: json);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.empresa, id: 5)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Personalizar'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('email_modelo_assunto')), 'Novo assunto');
      await tester.tap(find.byKey(const Key('email_modelo_salvar')));
      await tester.pumpAndSettle();

      final post = pedidos.firstWhere((r) => r.method == 'POST');
      final corpo = jsonDecode(post.body) as Map<String, dynamic>;
      expect(post.url.path, endsWith('/api/email-modelos'));
      expect(corpo['empresaId'], 5);
      expect(corpo['tipo'], 'BOAS_VINDAS');
      expect(corpo['assunto'], 'Novo assunto');
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('modelo proprio e alterado com PUT e pode ser excluido; herdado nao exclui', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      if (req.method == 'PUT') {
        return http.Response(jsonEncode(modelo(id: 9, tipo: 'REDEFINIR_SENHA', origem: 'EMPRESA', herdado: false)), 200, headers: json);
      }
      if (req.method == 'DELETE') return http.Response('', 200, headers: json);
      return http.Response(
        jsonEncode([modelo(id: 9, tipo: 'REDEFINIR_SENHA', origem: 'EMPRESA', herdado: false)]),
        200,
        headers: json,
      );
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.empresa, id: 5)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Alterar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('email_modelo_salvar')));
      await tester.pumpAndSettle();
      expect(pedidos.firstWhere((r) => r.method == 'PUT').url.path, endsWith('/api/email-modelos/9'));

      await tester.tap(find.byTooltip('Excluir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
      await tester.pumpAndSettle();
      expect(pedidos.any((r) => r.method == 'DELETE' && r.url.path.endsWith('/api/email-modelos/9')), isTrue);
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('erro do backend aparece na tela em vez de lista vazia silenciosa', (tester) async {
    final cliente = MockClient((req) async => http.Response('{"message":"x"}', 500, headers: json));

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.empresa, id: 5)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nao foi possivel carregar os modelos'), findsOneWidget);
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('campo desconhecido e script sao barrados antes de enviar', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      return http.Response(jsonEncode([modelo(id: 1, tipo: 'BOAS_VINDAS')]), 200, headers: json);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.empresa, id: 5)),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Personalizar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_modelo_html')), '<p>{{nome}} {{inventado}}</p>');
      await tester.tap(find.byKey(const Key('email_modelo_salvar')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Campos desconhecidos: {{inventado}}'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('email_modelo_html')), '<script>x</script>{{nome}}');
      await tester.tap(find.byKey(const Key('email_modelo_salvar')));
      await tester.pumpAndSettle();
      expect(find.textContaining('<script>'), findsWidgets);

      await tester.enterText(find.byKey(const Key('email_modelo_html')), '<p>sem o campo obrigatorio</p>');
      await tester.tap(find.byKey(const Key('email_modelo_salvar')));
      await tester.pumpAndSettle();
      expect(find.textContaining('precisa do campo {{nome}}'), findsOneWidget);

      expect(pedidos.where((r) => r.method == 'POST'), isEmpty);
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('sem id pede para salvar o cadastro antes', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EmailModelosTab(scope: SmtpConfigScope.empresa, id: 0)),
    ));
    expect(find.textContaining('Salve o cadastro'), findsOneWidget);
  });
}

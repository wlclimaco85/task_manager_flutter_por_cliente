import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/email_fila_tab.dart';
import 'package:task_manager_flutter/widgets/smtp_config_tab.dart';

void main() {
  const json = {'content-type': 'application/json; charset=utf-8'};

  Map<String, dynamic> item(int id, String status, {String? erro}) => {
        'id': id,
        'assunto': 'Assunto $id',
        'status': status,
        'destinatario': 'd$id@x.com',
        'tentativas': 1,
        'erro': erro,
      };

  Future<void> encerrar(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  http.Response resposta(http.Request req, List<Map<String, dynamic>> itens) {
    if (req.url.path.endsWith('/resumo')) {
      return http.Response(
          jsonEncode({'pendentes': 1, 'enviando': 0, 'enviados': 3, 'erros': 1, 'cancelados': 0}), 200, headers: json);
    }
    return http.Response(jsonEncode({'itens': itens, 'total': itens.length, 'pagina': 0, 'tamanho': 20}), 200, headers: json);
  }

  testWidgets('mostra o resumo, os itens e o motivo do erro', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      return resposta(req, [item(1, 'ENVIADO'), item(2, 'ERRO', erro: 'SMTP recusou')]);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailFilaTab(scope: SmtpConfigScope.empresa, id: 20001)),
      ));
      await tester.pumpAndSettle();

      expect(pedidos.any((r) => r.url.path.endsWith('/api/email-fila') && r.url.queryParameters['empresaId'] == '20001'), isTrue);
      expect(find.text('Enviados: 3'), findsOneWidget);
      expect(find.text('Com erro: 1'), findsOneWidget);
      expect(find.text('Motivo: SMTP recusou'), findsOneWidget);
      expect(find.byTooltip('Reenviar'), findsOneWidget); // so o item em erro
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('reenviar e cancelar chamam as acoes certas e recarregam a lista', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      if (req.method == 'POST') return http.Response(jsonEncode(item(2, 'PENDENTE')), 200, headers: json);
      return resposta(req, [item(2, 'ERRO', erro: 'x'), item(3, 'PENDENTE')]);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailFilaTab(scope: SmtpConfigScope.parceiro, id: 7)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Reenviar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Cancelar'));
      await tester.pumpAndSettle();

      final posts = pedidos.where((r) => r.method == 'POST').map((r) => r.url.path).toList();
      expect(posts.length, 2);
      expect(posts[0], endsWith('/api/email-fila/2/reenviar'));
      expect(posts[1], endsWith('/api/email-fila/3/cancelar'));
      expect(pedidos.first.url.queryParameters['parceiroId'], '7');
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('enviar teste faz POST no escopo e erro do backend vira aviso', (tester) async {
    final pedidos = <http.Request>[];
    final cliente = MockClient((req) async {
      pedidos.add(req);
      if (req.method == 'POST') return http.Response('{"message":"sem permissao"}', 403, headers: json);
      return resposta(req, []);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailFilaTab(scope: SmtpConfigScope.empresa, id: 5)),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('email_fila_teste')));
      await tester.pumpAndSettle();

      final post = pedidos.firstWhere((r) => r.method == 'POST');
      expect(post.url.path, endsWith('/api/email-fila/enviar-teste'));
      expect(jsonDecode(post.body)['empresaId'], 5);
      expect(find.textContaining('HTTP 403'), findsOneWidget);
    }, () => cliente);

    await encerrar(tester);
  });

  testWidgets('falha de rede mostra erro em vez de tela vazia', (tester) async {
    final cliente = MockClient((req) async => http.Response('{}', 500, headers: json));

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: EmailFilaTab(scope: SmtpConfigScope.empresa, id: 5)),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nao foi possivel carregar a fila'), findsOneWidget);
    }, () => cliente);

    await encerrar(tester);
  });
}

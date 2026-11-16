import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/dp_ferias_solicitacoes_view.dart';

http.Response _json(Object body, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status, headers: {'content-type': 'application/json; charset=utf-8'});

Future<void> _abrir(WidgetTester t, {required bool podeDecidir}) async {
  t.view.physicalSize = const Size(1000, 1200);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(home: Scaffold(body: DpFeriasSolicitacoesView(podeDecidir: podeDecidir))));
  await t.pumpAndSettle();
}

const _pedido = {
  'id': 5,
  'funcionarioId': 7,
  'funcionarioNome': 'Ana Souza',
  'dataInicio': '2027-01-10',
  'dataFim': '2027-01-24',
  'dias': 15,
  'status': 'SOLICITADA',
};

void main() {
  test('dpPodeDecidir reconhece gestor, master e admin da Conta Propria', () {
    expect(dpPodeDecidir(['ROLE_CONTA_PROPRIA_ADMIN']), isTrue);
    expect(dpPodeDecidir(['ROLE_CONTA_PROPRIA_DP']), isTrue);
    expect(dpPodeDecidir(['MASTER']), isTrue);
    expect(dpPodeDecidir(['GESTOR']), isTrue);
    expect(dpPodeDecidir(['ROLE_FUNCIONARIO', null]), isFalse);
    expect(dpPodeDecidir(const []), isFalse);
  });

  testWidgets('lista os pedidos de ferias com funcionario, periodo e status', (t) async {
    final client = MockClient((_) async => _json([_pedido]));
    await http.runWithClient(() async {
      await _abrir(t, podeDecidir: true);
      expect(find.text('Ana Souza'), findsOneWidget);
      expect(find.text('SOLICITADA'), findsOneWidget);
      expect(find.textContaining('15 dias'), findsOneWidget);
    }, () => client);
  });

  testWidgets('quem decide aprova na mesma lista: PUT com status APROVADA', (t) async {
    final puts = <Map<String, dynamic>>[];
    final client = MockClient((req) async {
      if (req.method == 'PUT') {
        puts.add({'url': req.url.path, 'body': jsonDecode(req.body)});
        return _json({..._pedido, 'status': 'APROVADA'});
      }
      return _json([_pedido]);
    });
    await http.runWithClient(() async {
      await _abrir(t, podeDecidir: true);
      await t.tap(find.byKey(const Key('ferias_item_5')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('ferias_aprovar')));
      await t.pumpAndSettle();
      expect(puts, hasLength(1));
      expect(puts.first['url'], endsWith('/api/dp/ferias-solicitacoes/5/status'));
      expect((puts.first['body'] as Map)['status'], 'APROVADA');
    }, () => client);
  });

  testWidgets('sem permissao de decidir, tocar no pedido nao abre a avaliacao', (t) async {
    final client = MockClient((_) async => _json([_pedido]));
    await http.runWithClient(() async {
      await _abrir(t, podeDecidir: false);
      await t.tap(find.byKey(const Key('ferias_item_5')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('ferias_aprovar')), findsNothing);
    }, () => client);
  });

  testWidgets('erro do servidor aparece na tela (nao fica em branco)', (t) async {
    final client = MockClient((_) async => _json({'message': 'Sem permissão (ver) na tela SolicitarAjuste'}, 403));
    await http.runWithClient(() async {
      await _abrir(t, podeDecidir: true);
      expect(find.textContaining('Sem permissão'), findsOneWidget);
    }, () => client);
  });

  testWidgets('dialogo de solicitacao mostra o saldo e o vencimento do periodo aquisitivo', (t) async {
    final client = MockClient((req) async {
      final path = req.url.path;
      if (path.endsWith('/saldo')) {
        return _json([
          {
            'aquisitivoInicio': '2025-03-01',
            'aquisitivoFim': '2026-02-28',
            'concessivoFim': '2027-02-28',
            'saldoDias': 30,
            'situacao': 'DISPONIVEL',
          },
          {'aquisitivoInicio': '2026-03-01', 'aquisitivoFim': '2027-02-28', 'concessivoFim': '2028-02-29', 'saldoDias': 0, 'situacao': 'EM_AQUISICAO'},
        ]);
      }
      if (path.endsWith('/api/funcionario')) {
        return _json({
          'data': {
            'dados': [
              {'id': 7, 'nome': 'Ana Souza'}
            ]
          }
        });
      }
      return _json(<Object>[]);
    });
    await http.runWithClient(() async {
      final key = GlobalKey<DpFeriasSolicitacoesViewState>();
      t.view.physicalSize = const Size(1000, 1200);
      t.view.devicePixelRatio = 1.0;
      addTearDown(t.view.reset);
      await t.pumpWidget(MaterialApp(home: Scaffold(body: DpFeriasSolicitacoesView(key: key, podeDecidir: true))));
      await t.pumpAndSettle();

      key.currentState!.solicitar();
      await t.pumpAndSettle();

      expect(find.byKey(const Key('ferias_saldo')), findsOneWidget);
      expect(find.textContaining('Saldo: 30 dia(s)'), findsOneWidget);
    }, () => client);
  });

  testWidgets('pedido aprovado abre o dialogo com o aviso de ferias em PDF', (t) async {
    final client = MockClient((_) async => _json([
          {..._pedido, 'status': 'APROVADA'}
        ]));
    await http.runWithClient(() async {
      await _abrir(t, podeDecidir: false);
      await t.tap(find.byKey(const Key('ferias_item_5')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('ferias_aviso')), findsOneWidget);
    }, () => client);
  });
}

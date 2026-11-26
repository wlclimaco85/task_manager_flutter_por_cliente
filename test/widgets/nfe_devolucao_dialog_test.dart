import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_manager_flutter/widgets/nfe_devolucao_dialog.dart';

void main() {
  const json = {'content-type': 'application/json; charset=utf-8'};

  Map<String, dynamic> item(int id, String cProd, String xProd, num qtd) =>
      {'id': id, 'c_prod': cProd, 'x_prod': xProd, 'q_com': qtd};

  Future<NfeDevolucaoEscolha?> abrir(WidgetTester tester, http.Client cliente) async {
    NfeDevolucaoEscolha? resultado;
    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async {
                resultado = await mostrarDialogoDevolucaoNfe(ctx, {'id': 809, 'numero': '3073375', 'chave': '3126'});
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }, () => cliente);
    return resultado;
  }

  testWidgets('traz todos os itens marcados e devolve so o MACARICO ao desmarcar os outros', (tester) async {
    final cliente = MockClient((req) async => http.Response(
          jsonEncode({
            'data': {
              'dados': [
                item(1, '100001', 'OUTRO PRODUTO', 4),
                item(2, '122065', 'MACARICO - PROTECNI', 1),
              ],
            },
          }),
          200,
          headers: json,
        ));

    await abrir(tester, cliente);
    expect(find.text('100001 - OUTRO PRODUTO'), findsOneWidget);
    expect(find.text('122065 - MACARICO - PROTECNI'), findsOneWidget);
    expect(find.textContaining('2 de 2 para devolver'), findsOneWidget);

    // desmarca o item 1; fica so o MACARICO (item 2)
    await tester.tap(find.descendant(of: find.byKey(const Key('devolucao_item_1')), matching: find.byType(Checkbox)));
    await tester.pump();
    expect(find.textContaining('1 de 2 para devolver'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('devolucao_motivo')), 'Produto errado');
    await tester.tap(find.byKey(const Key('devolucao_confirmar')));
    await tester.pumpAndSettle();

    // o dialogo fechou devolvendo a escolha
    expect(find.byKey(const Key('devolucao_confirmar')), findsNothing);
  });

  testWidgets('nota sem itens: Continuar assim mesmo devolve escolha sem itens para abrir a devolucao em edicao', (tester) async {
    NfeDevolucaoEscolha? escolha;
    final cliente = MockClient((req) async => http.Response(jsonEncode([]), 200, headers: json));

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async => escolha = await mostrarDialogoDevolucaoNfe(ctx, {'id': 809, 'chave': '3126'}),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('devolucao_continuar_sem_itens')));
      await tester.pumpAndSettle();
    }, () => cliente);

    expect(escolha, isNotNull);
    expect(escolha!.semItens, isTrue);
    expect(escolha!.itens, isEmpty);
    expect(escolha!.motivo, 'Devolução de mercadoria');
  });

  testWidgets('a escolha devolvida tem so os itens marcados com a quantidade informada', (tester) async {
    NfeDevolucaoEscolha? escolha;
    final cliente = MockClient((req) async => http.Response(
          jsonEncode([item(1, '100001', 'OUTRO PRODUTO', 4), item(2, '122065', 'MACARICO - PROTECNI', 1)]),
          200,
          headers: json,
        ));

    await http.runWithClient(() async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async => escolha = await mostrarDialogoDevolucaoNfe(ctx, {'id': 809}),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      await tester.tap(find.descendant(of: find.byKey(const Key('devolucao_item_1')), matching: find.byType(Checkbox)));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('devolucao_motivo')), 'Produto errado');
      await tester.tap(find.byKey(const Key('devolucao_confirmar')));
      await tester.pumpAndSettle();
    }, () => cliente);

    expect(escolha, isNotNull);
    expect(escolha!.motivo, 'Produto errado');
    expect(escolha!.itens, [
      {'id': 2, 'quantidade': 1.0}
    ]);
  });

  testWidgets('quantidade acima da nota e nenhum item marcado sao barrados antes de enviar', (tester) async {
    final cliente = MockClient((req) async => http.Response(
          jsonEncode([item(1, '100001', 'OUTRO PRODUTO', 4)]),
          200,
          headers: json,
        ));

    await abrir(tester, cliente);

    await tester.enterText(
        find.descendant(of: find.byKey(const Key('devolucao_item_1')), matching: find.byType(TextField)), '5');
    await tester.tap(find.byKey(const Key('devolucao_confirmar')));
    await tester.pump();
    expect(find.textContaining('não pode passar de 4'), findsOneWidget);

    await tester.tap(find.descendant(of: find.byKey(const Key('devolucao_item_1')), matching: find.byType(Checkbox)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('devolucao_confirmar')));
    await tester.pump();
    expect(find.textContaining('Marque pelo menos um item'), findsOneWidget);
  });

  testWidgets('nota importada da SEFAZ sem itens oferece Buscar XML SEFAZ e recarrega os itens', (tester) async {
    var xmlBuscado = false;
    final cliente = MockClient((req) async {
      if (req.method == 'POST' && req.url.path.endsWith('/buscar-xml-sefaz')) {
        xmlBuscado = true;
        return http.Response('{}', 200, headers: json);
      }
      final itens = xmlBuscado ? [item(2, '122065', 'MACARICO - PROTECNI', 1)] : [];
      return http.Response(jsonEncode(itens), 200, headers: json);
    });

    await abrir(tester, cliente);
    expect(find.textContaining('não tem itens'), findsOneWidget);

    await http.runWithClient(() async {
      await tester.tap(find.byKey(const Key('devolucao_buscar_xml')));
      await tester.pumpAndSettle();
    }, () => cliente);

    expect(xmlBuscado, isTrue);
    expect(find.text('122065 - MACARICO - PROTECNI'), findsOneWidget);
  });

  testWidgets('nota sem itens mostra campo de produto e botao Adicionar desabilitado sem produto escolhido', (tester) async {
    final cliente = MockClient((req) async => http.Response(jsonEncode([]), 200, headers: json));

    await abrir(tester, cliente);

    expect(find.byKey(const Key('devolucao_produto')), findsOneWidget);
    final botao = tester.widget<OutlinedButton>(find.byKey(const Key('devolucao_adicionar_produto')));
    expect(botao.onPressed, isNull);
  });

  test('XML importado so e aceito se tiver a mesma chave da nota e itens', () {
    const chave = '31261114190675000317550060030733751371733145';
    const outra = '31261114190675000317550050052807191371733999';
    String xml(String c, {bool comItens = true}) =>
        '<nfeProc><NFe><infNFe Id="NFe$c" versao="4.00">${comItens ? '<det nItem="1"></det>' : ''}</infNFe></NFe></nfeProc>';

    expect(erroXmlDiferenteDaNota(xml(chave), chave), isNull);
    expect(erroXmlDiferenteDaNota(xml(outra), chave), contains('chave $outra'));
    expect(erroXmlDiferenteDaNota(xml(chave, comItens: false), chave), contains('não tem itens'));
    expect(erroXmlDiferenteDaNota('<html></html>', chave), contains('não é um XML de NF-e'));
    expect(erroXmlDiferenteDaNota(xml(chave), '123'), contains('chave de acesso válida'));
  });

  testWidgets('nota sem itens oferece importar XML por arquivo', (tester) async {
    final cliente = MockClient((req) async => http.Response(jsonEncode([]), 200, headers: json));

    await abrir(tester, cliente);

    // Barra de acoes com os 4 botoes: Cancelar, Importar XML, Fazer manual e Confirmar Devolucao.
    expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Importar XML'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Fazer manual'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Confirmar Devolução'), findsOneWidget);
  });

  test('produto escolhido vira o corpo do item (segue marcado na devolucao manual)', () {
    final c = corpoItemDoProduto(
        {'id': 7, 'codigo': 'A1', 'nome': 'PROD', 'ncm': '1234', 'cfop': '5102', 'unidade': 'un'},
        qtd: 2, preco: 3.5, nfeId: 811);

    expect(c['nfe_id'], 811);
    expect(c['produto'], {'id': 7});
    expect(c['x_prod'], 'PROD');
    expect(c['u_com'], 'UN');
    expect(c['q_com'], 2);
    expect(c['v_prod'], 7.0);
    expect(corpoItemDoProduto({'id': 7}, qtd: 1, preco: 1).containsKey('nfe_id'), isFalse);
  });

  testWidgets('erro ao carregar os itens aparece no dialogo', (tester) async {
    final cliente = MockClient((req) async => http.Response('{}', 500, headers: json));

    await abrir(tester, cliente);

    expect(find.textContaining('Não foi possível carregar os itens'), findsOneWidget);
  });
}

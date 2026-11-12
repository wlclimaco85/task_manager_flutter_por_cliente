import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/documento_fiscal_grid.dart';

void main() {
  final itens = <Map<String, dynamic>>[
    {'id': 1, 'numero': 10, 'status': 'AUTORIZADO', 'tpAmb': 2},
    {'id': 2, 'numero': 11, 'status': 'REJEITADO', 'tpAmb': 2},
  ];

  List<List<Map<String, dynamic>>> chamadas = [];

  Widget montar({double largura = 1000}) {
    chamadas = [];
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: Size(largura, 800)),
        child: Scaffold(
          body: SizedBox(
            width: largura,
            height: 800,
            child: DocumentoFiscalGrid(
              itens: itens,
              colunas: [
                DocColuna('Nº', (m) => '${m['numero']}', largura: 70),
                DocColuna('Série', (m) => '1', largura: 60),
              ],
              corStatus: (_) => Colors.green,
              textoVazio: 'vazio',
              acoes: [
                DocAcao(
                  icone: Icons.sync,
                  rotulo: 'Consultar',
                  habilitada: (l) => l.isNotEmpty,
                  executar: (l) async => chamadas.add(l),
                ),
                DocAcao(
                  icone: Icons.cancel,
                  rotulo: 'Cancelar',
                  habilitada: (l) =>
                      l.isNotEmpty && l.every((m) => m['status'] == 'AUTORIZADO'),
                  executar: (l) async => chamadas.add(l),
                ),
                DocAcao(
                  icone: Icons.history,
                  rotulo: 'Eventos',
                  soUm: true,
                  habilitada: (l) => l.length == 1,
                  executar: (l) async => chamadas.add(l),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sem selecao o menu Ações fica desabilitado', (t) async {
    await t.pumpWidget(montar());
    final menu = t.widget<PopupMenuButton<DocAcao>>(find.byType(PopupMenuButton<DocAcao>).first);
    expect(menu.enabled, isFalse);
    expect(find.text('Selecionar todos'), findsOneWidget);
  });

  testWidgets('selecionar todos habilita só as ações válidas para todos e executa em lote', (t) async {
    await t.pumpWidget(montar());
    await t.tap(find.byType(Checkbox).first); // selecionar todos
    await t.pump();
    expect(find.text('2 de 2 selecionado(s)'), findsOneWidget);

    await t.tap(find.text('Ações (2)'));
    await t.pumpAndSettle();
    expect(find.text('Consultar'), findsOneWidget);
    // Cancelar exige que TODOS estejam autorizados; Eventos é só por documento
    expect(find.text('Cancelar'), findsNothing);
    expect(find.text('Eventos'), findsNothing);

    await t.tap(find.text('Consultar'));
    await t.pumpAndSettle();
    expect(chamadas.single.map((m) => m['id']), [1, 2]);
  });

  testWidgets('selecionando só o autorizado, Cancelar passa a valer', (t) async {
    await t.pumpWidget(montar());
    await t.tap(find.byType(Checkbox).at(1)); // primeira linha
    await t.pump();
    await t.tap(find.text('Ações (1)'));
    await t.pumpAndSettle();
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Eventos'), findsNothing);
  });

  testWidgets('menu da linha oferece as ações do documento, inclusive as só-um', (t) async {
    await t.pumpWidget(montar());
    await t.tap(find.byIcon(Icons.more_vert).last); // linha rejeitada
    await t.pumpAndSettle();
    expect(find.text('Consultar'), findsOneWidget);
    expect(find.text('Eventos'), findsOneWidget);
    expect(find.text('Cancelar'), findsNothing); // rejeitado nao cancela
    await t.tap(find.text('Eventos'));
    await t.pumpAndSettle();
    expect(chamadas.single.single['id'], 2);
  });

  testWidgets('no celular vira lista de cartões com os mesmos controles', (t) async {
    await t.pumpWidget(montar(largura: 380));
    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Nº 10 • Série 1'), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
  });

  testWidgets('lista vazia mostra o texto de vazio', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: DocumentoFiscalGrid(
          itens: const [],
          colunas: [DocColuna('Nº', (m) => '')],
          acoes: const [],
          corStatus: (_) => Colors.grey,
          textoVazio: 'Nenhum MDF-e emitido.',
        ),
      ),
    ));
    expect(find.text('Nenhum MDF-e emitido.'), findsOneWidget);
  });

  testWidgets('acao que lanca excecao mostra SnackBar e libera o menu (sem estourar)', (t) async {
    await t.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 1000,
          height: 800,
          child: DocumentoFiscalGrid(
            itens: itens,
            colunas: [DocColuna('Nº', (m) => '${m['numero']}', largura: 70)],
            corStatus: (_) => Colors.green,
            textoVazio: 'vazio',
            acoes: [
              DocAcao(
                icone: Icons.sync,
                rotulo: 'Consultar',
                habilitada: (l) => l.isNotEmpty,
                executar: (l) async => throw Exception('falha simulada'),
              ),
            ],
          ),
        ),
      ),
    ));
    await t.tap(find.byType(Checkbox).first);
    await t.pump();
    await t.tap(find.text('Ações (2)'));
    await t.pumpAndSettle();
    await t.tap(find.text('Consultar'));
    await t.pumpAndSettle();
    expect(find.textContaining('Falha ao executar "Consultar"'), findsOneWidget);
    final menu = t.widget<PopupMenuButton<DocAcao>>(find.byType(PopupMenuButton<DocAcao>).first);
    expect(menu.enabled, isTrue);
  });

  group('DocumentoFiscalListagem (filtros)', () {
    final docs = <Map<String, dynamic>>[
      {'id': 1, 'numero': 10, 'status': 'AUTORIZADO', 'tpAmb': 2, 'chaveAcesso': 'AAA111', 'tipoCte': 0},
      {'id': 2, 'numero': 11, 'status': 'REJEITADO', 'tpAmb': 2, 'chaveAcesso': 'BBB222', 'tipoCte': 1},
      {'id': 3, 'numero': 12, 'status': 'AUTORIZADO', 'tpAmb': 1, 'protocolo': 'PROT333', 'tipoCte': 0},
    ];

    Widget montar(List<Map<String, dynamic>> itens, {Map<int, String>? tipos, double largura = 1200}) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(largura, 800)),
          child: Scaffold(
            body: SizedBox(
              width: largura,
              height: 800,
              child: DocumentoFiscalListagem(
                itens: itens,
                colunas: [
                  DocColuna('Nº', (m) => '${m['numero']}', largura: 70),
                  DocColuna('Série', (m) => '1', largura: 60),
                ],
                acoes: const [],
                corStatus: (_) => Colors.green,
                textoVazio: 'Nenhum documento emitido.',
                statusOpcoes: const ['AUTORIZADO', 'REJEITADO'],
                tipos: tipos,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('painel de filtros aparece mesmo com a lista vazia', (t) async {
      await t.pumpWidget(montar(const []));
      expect(find.text('Filtros'), findsOneWidget);
      expect(find.text('Buscar nº, chave ou protocolo'), findsOneWidget);
      expect(find.text('Nenhum documento emitido.'), findsOneWidget);
    });

    testWidgets('busca por numero, chave ou protocolo', (t) async {
      await t.pumpWidget(montar(docs));
      expect(find.text('3 documento(s)'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'prot333');
      await t.pump();
      expect(find.text('1 de 3 documento(s)'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'bbb');
      await t.pump();
      expect(find.text('1 de 3 documento(s)'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'zzz');
      await t.pump();
      expect(find.text('Nenhum documento encontrado com os filtros.'), findsOneWidget);
    });

    testWidgets('filtra por situacao e Limpar filtros restaura tudo', (t) async {
      await t.pumpWidget(montar(docs));
      await t.tap(find.text('Todas'));
      await t.pumpAndSettle();
      await t.tap(find.text('REJEITADO').last);
      await t.pumpAndSettle();
      expect(find.text('1 de 3 documento(s)'), findsOneWidget);

      await t.tap(find.text('Limpar filtros'));
      await t.pumpAndSettle();
      expect(find.text('3 documento(s)'), findsOneWidget);
    });

    testWidgets('filtra por ambiente', (t) async {
      await t.pumpWidget(montar(docs));
      await t.tap(find.text('Todos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Produção').last);
      await t.pumpAndSettle();
      expect(find.text('1 de 3 documento(s)'), findsOneWidget);
    });

    testWidgets('filtro por tipo so existe quando tipos e informado (CT-e)', (t) async {
      await t.pumpWidget(montar(docs));
      expect(find.text('Tipo'), findsNothing);
      await t.pumpWidget(montar(docs, tipos: const {0: 'Normal', 1: 'Complemento'}));
      expect(find.text('Tipo'), findsOneWidget);
    });

    testWidgets('painel pode ser recolhido e reaberto', (t) async {
      await t.pumpWidget(montar(docs));
      await t.tap(find.byTooltip('Ocultar filtros'));
      await t.pumpAndSettle();
      expect(find.text('Filtros'), findsNothing);
      await t.tap(find.byTooltip('Mostrar filtros'));
      await t.pumpAndSettle();
      expect(find.text('Filtros'), findsOneWidget);
    });

    testWidgets('no celular os filtros viram um bloco recolhivel acima da grid', (t) async {
      await t.pumpWidget(montar(docs, largura: 380));
      expect(find.byType(ExpansionTile), findsOneWidget);
      await t.tap(find.text('Filtros'));
      await t.pumpAndSettle();
      expect(find.text('Buscar nº, chave ou protocolo'), findsOneWidget);
    });
  });
}

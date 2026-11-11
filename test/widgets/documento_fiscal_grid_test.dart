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
}

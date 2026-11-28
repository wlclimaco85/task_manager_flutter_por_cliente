import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/menu_publicado_service.dart';
import 'package:task_manager_flutter/services/planilha_service.dart';
import 'package:task_manager_flutter/widgets/planilha_view.dart';

class _Planilhas extends PlanilhaService {
  final consultasDeCampo = <Map<String, String>>[];

  @override
  Future<List<PlanilhaResumo>> listar() async => const [];

  @override
  Future<List<FontePlanilha>> fontes() async => const [];

  @override
  Future<ConsultaPlanilha> consultar(String sql) async => const ConsultaPlanilha(['codigo', 'qtd'], [
        [10, 2],
        [20, 3]
      ], false);

  @override
  Future<ConsultaPlanilha> consultarCampo(String sql, Map<String, String> parametros) async {
    consultasDeCampo.add(parametros);
    return ConsultaPlanilha(const [
      'nome'
    ], [
      ['Item ${parametros['cod']}']
    ], false);
  }
}

class _Menu extends MenuPublicadoService {
  ModeloPlanilha? salvo;

  @override
  Future<ModeloPlanilha> salvarModelo(ModeloPlanilha m) async {
    salvo = m;
    return ModeloPlanilha(id: 7, titulo: m.titulo, celulas: m.celulas, fontes: m.fontes);
  }
}

void main() {
  testWidgets('construtor: edita a fonte, soma a coluna e preenche um campo por SELECT', (t) async {
    t.view.physicalSize = const Size(1600, 1000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final planilhas = _Planilhas();
    final menu = _Menu();
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PlanilhaView(
                servico: planilhas,
                menu: menu,
                podeConsultar: true,
                edicaoModelo: const ModeloPlanilha(titulo: 'Pedido', fontes: [
                  FonteModelo(celula: 'A1', sql: 'SELECT codigo, qtd FROM item', rotulos: {'qtd': 'Quantidade'})
                ])))));
    await t.pumpAndSettle();

    // editar: abre com o SELECT atual e marca a soma da quantidade
    await t.tap(find.text('Fontes (1)'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Editar fonte'));
    await t.pumpAndSettle();
    expect(find.text('SELECT codigo, qtd FROM item'), findsOneWidget);
    await t.ensureVisible(find.byKey(const ValueKey('somar-qtd')));
    await t.tap(find.byKey(const ValueKey('somar-qtd')));
    await t.pump();
    await t.tap(find.text('Salvar fonte'));
    await t.pumpAndSettle();
    expect(find.text('Total'), findsNothing);
    expect(find.text('5'), findsWidgets);

    // campo: cada linha de dados consulta com o codigo da coluna A
    await t.tap(find.text('Campo por SELECT'));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('campo-celula')), 'c2');
    await t.enterText(find.byKey(const Key('campo-sql')),
        'SELECT nome FROM produto WHERE id = :cod AND empresa_id = :empresaId');
    await t.pump();
    expect(find.byKey(const ValueKey('param-empresaid')), findsNothing);
    await t.tap(find.text('Salvar campo'));
    await t.pump();
    expect(find.text('Escolha a coluna de cada parâmetro.'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('param-cod')));
    await t.pumpAndSettle();
    await t.tap(find.text('A - codigo').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Salvar campo'));
    await t.pumpAndSettle();

    expect(find.text('Item 10'), findsWidgets);
    expect(find.text('Item 20'), findsWidgets);
    // a linha de total so tem a soma: nao vira codigo de consulta
    expect(planilhas.consultasDeCampo.map((p) => p['cod']), ['10', '20']);

    await t.tap(find.text('Salvar modelo'));
    await t.pumpAndSettle();
    final fontes = menu.salvo!.fontes;
    expect(fontes.map((f) => f.celula), ['A1', 'C2']);
    expect(fontes.first.somas, ['qtd']);
    expect(fontes.first.rotulos, {'qtd': 'Quantidade'});
    expect(fontes.last.parametros, {'cod': 'A'});
    expect(menu.salvo!.celulas, isEmpty);
  });
}

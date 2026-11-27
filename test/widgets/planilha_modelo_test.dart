import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/menu_publicado_service.dart';
import 'package:task_manager_flutter/services/planilha_service.dart';
import 'package:task_manager_flutter/widgets/planilha_view.dart';

class _Planilhas extends PlanilhaService {
  @override
  Future<List<PlanilhaResumo>> listar() async => const [];

  @override
  Future<List<FontePlanilha>> fontes() async => const [FontePlanilha('produto', 'Produtos')];

  @override
  Future<Map<String, String>> campos(String tabela) async => const {'nome': 'Nome do produto'};

  @override
  Future<ConsultaPlanilha> consultar(String sql) async => const ConsultaPlanilha(['nome'], [
        ['Cafe']
      ], false);
}

class _Menu extends MenuPublicadoService {
  ModeloPlanilha? salvo;
  int aberturas = 0;

  @override
  Future<ModeloPlanilha> salvarModelo(ModeloPlanilha m) async {
    salvo = m;
    return ModeloPlanilha(id: 7, titulo: m.titulo, celulas: m.celulas, fontes: m.fontes);
  }

  @override
  Future<ModeloAberto> abrirModelo(int id) async =>
      ModeloAberto('Precos', {'A1': 'Cafe ${++aberturas}'}, false);
}

void main() {
  Future<void> montar(WidgetTester t, Widget w) async {
    t.view.physicalSize = const Size(1600, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: w)));
    await t.pumpAndSettle();
  }

  testWidgets('construtor: guarda a consulta como fonte do modelo, sem copiar os dados', (t) async {
    final menu = _Menu();
    await montar(t,
        PlanilhaView(servico: _Planilhas(), menu: menu, podeConsultar: true, edicaoModelo: const ModeloPlanilha(titulo: 'Precos')));
    expect(find.text('Dados do sistema'), findsNothing);
    await t.tap(find.byKey(const ValueKey('B2')));
    await t.pump();
    await t.tap(find.text('Fonte de dados'));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownMenu<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Produtos (produto)').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Consultar'));
    await t.pumpAndSettle();
    await t.tap(find.text('Inserir na célula'));
    await t.pumpAndSettle();
    await t.tap(find.text('Salvar modelo'));
    await t.pumpAndSettle();

    final fonte = menu.salvo!.fontes.single;
    expect(fonte.celula, 'B2');
    expect(fonte.sql, 'SELECT nome\nFROM produto\nWHERE empresa_id = :empresaId');
    expect(fonte.rotulos, {'nome': 'Nome do produto'});
    expect(menu.salvo!.celulas, isEmpty);
    expect(find.text('Fontes (1)'), findsOneWidget);
    // a previa aparece na grade (cabecalho na B2, dado na B3) mas nao foi para o modelo salvo
    expect(find.text('Nome do produto'), findsWidgets);
    expect(find.text('Cafe'), findsWidgets);

    final antes = t.getSize(find.byKey(const ValueKey('C5'))).width;
    await t.tap(find.byTooltip('Diminuir largura das colunas'));
    await t.pump();
    expect(t.getSize(find.byKey(const ValueKey('C5'))).width, antes - 20);
    await t.tap(find.byTooltip('Aumentar largura das colunas'));
    await t.pump();
    expect(t.getSize(find.byKey(const ValueKey('C5'))).width, antes);
  });

  testWidgets('item publicado: abre com dados atuais, atualiza e so salva copia', (t) async {
    final menu = _Menu();
    await montar(t, PlanilhaView(servico: _Planilhas(), menu: menu, podeConsultar: true, modeloId: 7));
    expect(find.text('Cafe 1'), findsWidgets);
    expect(find.text('Salvar cópia'), findsOneWidget);
    expect(find.text('Dados do sistema'), findsNothing);
    await t.tap(find.text('Atualizar dados'));
    await t.pumpAndSettle();
    expect(find.text('Cafe 2'), findsWidgets);
  });
}

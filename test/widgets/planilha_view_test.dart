import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/services/planilha_service.dart';
import 'package:task_manager_flutter/widgets/planilha_view.dart';

class _Falso extends PlanilhaService {
  PlanilhaDados? salvo;

  @override
  Future<List<PlanilhaResumo>> listar() async => const [];

  @override
  Future<PlanilhaDados> salvar(PlanilhaDados p) async {
    salvo = p;
    return PlanilhaDados(id: 1, nome: p.nome, celulas: p.celulas);
  }
}

void main() {
  Future<void> montar(WidgetTester t, _Falso s, {required bool master}) async {
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: PlanilhaView(servico: s, podeConsultar: master))));
    await t.pumpAndSettle();
  }

  testWidgets('digita, calcula formula e salva', (t) async {
    final s = _Falso();
    await montar(t, s, master: false);
    await t.enterText(find.byKey(const ValueKey('editor-A1')), '40');
    await t.tap(find.byKey(const ValueKey('B1')));
    await t.pump();
    await t.enterText(find.byKey(const Key('barra-formula')), '=A1+2');
    await t.tap(find.byKey(const ValueKey('C1')));
    await t.pump();
    expect(find.text('42'), findsOneWidget);
    await t.tap(find.text('Salvar'));
    await t.pumpAndSettle();
    expect(s.salvo!.celulas, {'A1': '40', 'B1': '=A1+2'});
    expect(find.text('Dados do sistema'), findsNothing);
  });

  testWidgets('MASTER ve os dados do sistema', (t) async {
    await montar(t, _Falso(), master: true);
    expect(find.text('Dados do sistema'), findsOneWidget);
  });
}

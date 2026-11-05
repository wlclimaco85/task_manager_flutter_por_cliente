import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/utils/mensalidade_referencia_filtro.dart';

void main() {
  group('paramsVencimento (referencia = competencia, vencimento no mes seguinte)', () {
    test('sem filtro nao envia parametros', () {
      expect(MensalidadeReferenciaFiltro.paramsVencimento(), isEmpty);
    });

    test('outubro/2026 -> vencimento em novembro/2026', () {
      expect(MensalidadeReferenciaFiltro.paramsVencimento(mes: 10, ano: 2026), {
        'dataVencimentoInicio': '2026-11-01',
        'dataVencimentoFim': '2026-11-30',
      });
    });

    test('dezembro/2026 -> vencimento em janeiro/2027', () {
      expect(MensalidadeReferenciaFiltro.paramsVencimento(mes: 12, ano: 2026), {
        'dataVencimentoInicio': '2027-01-01',
        'dataVencimentoFim': '2027-01-31',
      });
    });

    test('so o ano cobre jan..dez (vencimentos fev/ano a jan/ano+1)', () {
      expect(MensalidadeReferenciaFiltro.paramsVencimento(ano: 2026), {
        'dataVencimentoInicio': '2026-02-01',
        'dataVencimentoFim': '2027-01-31',
      });
    });

    test('so o mes usa o ano corrente informado', () {
      expect(
          MensalidadeReferenciaFiltro.paramsVencimento(
              mes: 1, agora: DateTime(2026, 11, 5)),
          {'dataVencimentoInicio': '2026-02-01', 'dataVencimentoFim': '2026-02-28'});
    });
  });

  testWidgets('dropdowns Referencia e Ano notificam a escolha', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    int? mes;
    int? ano;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => MensalidadeReferenciaAnoFiltros(
            mes: mes,
            ano: ano,
            onMesChanged: (v) => setState(() => mes = v),
            onAnoChanged: (v) => setState(() => ano = v),
          ),
        ),
      ),
    ));

    expect(find.text('Referência:'), findsOneWidget);
    expect(find.text('Ano:'), findsOneWidget);

    await tester.tap(find.byKey(const Key('mensalidade-filtro-referencia')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Outubro').last);
    await tester.tap(find.text('Outubro').last);
    await tester.pumpAndSettle();
    expect(mes, 10);

    await tester.tap(find.byKey(const Key('mensalidade-filtro-ano')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${DateTime.now().year}').last);
    await tester.pumpAndSettle();
    expect(ano, DateTime.now().year);
  });
}

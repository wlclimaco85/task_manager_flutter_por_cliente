import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_grid_windows_screen.dart';

Future<void> _montar(WidgetTester tester, List<FieldConfigWindows> campos,
    List<Map<String, dynamic>> itens) async {
  tester.view.physicalSize = const Size(1600, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: GenericGridScreen<Map<String, dynamic>>(
        title: 'Contas',
        fetchEndpoint: 'http://dummy/api/contas',
        createEndpoint: 'http://dummy/api/contas',
        updateEndpoint: 'http://dummy/api/contas',
        deleteEndpoint: 'http://dummy/api/contas',
        fromJson: (json) => json,
        toJson: (item) => item,
        hasPermission: (_) => true,
        FieldConfigWindowss: campos,
        idFieldName: 'id',
      ),
    ),
  ));
  final state = tester.state<GenericGridScreenState<Map<String, dynamic>>>(
    find.byType(GenericGridScreen<Map<String, dynamic>>),
  );
  state.setState(() {
    state.items = itens;
    state.filtered = itens;
    state.isLoading = false;
  });
  await tester.pumpAndSettle();
}

void main() {
  const id = FieldConfigWindows(label: 'Id', fieldName: 'id', isInForm: false);
  const nome = FieldConfigWindows(label: 'Nome', fieldName: 'nome');
  final itens = [
    {'id': 1, 'nome': 'A', 'valor': 100.5},
    {'id': 2, 'nome': 'B', 'valor': 49.5},
  ];

  testWidgets('grid com campo currency mostra o total da pagina no rodape', (tester) async {
    await _montar(tester, const [
      id,
      nome,
      FieldConfigWindows(label: 'Valor', fieldName: 'valor', fieldType: FieldType.currency),
    ], itens);

    expect(find.text('Total da página:'), findsOneWidget);
    expect(find.textContaining('150,00'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('grid sem campo numerico somavel nao mostra rodape de totais', (tester) async {
    await _montar(tester, const [id, nome], itens);

    expect(find.text('Total da página:'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  });
}

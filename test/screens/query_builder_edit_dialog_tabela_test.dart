import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/web/screens/query_builder_edit_dialog.dart';

void main() {
  testWidgets(
      'sem nome da tabela nos metadados mostra erro e libera o botao Salvar (nao fica girando)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => showEditRowDialog(
              context,
              schema: 'public',
              colunas: const [
                {'nome': 'id', 'tipo': 'int4'},
                {'nome': 'description', 'tipo': 'varchar'},
              ],
              rowData: const {'id': 1, 'description': 'antiga'},
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'nova descricao');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nome da tabela'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

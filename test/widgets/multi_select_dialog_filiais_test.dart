import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager_flutter/widgets/generic_detail_form_screen.dart';

void main() {
  testWidgets('popup de filiais filtra por busca e permite marcar varios',
      (tester) async {
    List<dynamic>? resultado;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            resultado = await showMultiSelectDialog(
              context,
              title: 'Vincular filiais',
              options: [
                {'id': 1, 'label': 'ALFA LTDA', 'cnpj': '111'},
                {'id': 2, 'label': 'BETA LTDA', 'cnpj': '222'},
                {'id': 3, 'label': 'ALFAZEMA SA', 'cnpj': '333'},
              ],
              subtitleField: 'cnpj',
            );
          },
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('222'), findsOneWidget); // cnpj embaixo do nome

    await tester.enterText(find.byType(TextField), 'alfa');
    await tester.pumpAndSettle();
    expect(find.text('BETA LTDA'), findsNothing);

    await tester.tap(find.text('ALFA LTDA'));
    await tester.tap(find.text('ALFAZEMA SA'));
    await tester.tap(find.text('CONFIRMAR'));
    await tester.pumpAndSettle();

    expect(resultado, [1, 3]);
  });
}
